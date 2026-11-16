<?php

namespace Tests\Feature;

use App\Models\Material;
use App\Models\MaterialBatch;
use App\Models\User;
use App\Models\WarehouseLocation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\DB;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReceiveBatchTest extends TestCase
{
    use RefreshDatabase;

    private Material $material;
    private WarehouseLocation $shelf;

    protected function setUp(): void
    {
        parent::setUp();

        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_WORKER]));

        $this->material = Material::create([
            'name' => 'Blacha DC01',
            'weight' => 25.5,
            'length' => 2000,
            'thickness' => 2,
        ]);

        $sector = WarehouseLocation::create(['code' => 'S1', 'name' => 'Sektor 1', 'type' => 'sektor']);
        $rack = WarehouseLocation::create(['code' => 'S1-R1', 'name' => 'Regał 1', 'type' => 'regal', 'parent_id' => $sector->id]);
        $this->shelf = WarehouseLocation::create(['code' => 'S1-R1-P1', 'name' => 'Półka 1', 'type' => 'polka', 'parent_id' => $rack->id]);
    }

    public function test_receiving_material_creates_batch_and_movement(): void
    {
        $response = $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
        ]);

        $response->assertCreated()
            ->assertJsonPath('batch_code', 'BL-0001')
            ->assertJsonPath('quantity', 10)
            ->assertJsonPath('status', MaterialBatch::STATUS_IN_STOCK)
            ->assertJsonPath('material.name', 'Blacha DC01')
            ->assertJsonPath('current_location.code', 'S1-R1-P1');

        $this->assertDatabaseCount('material_batches', 1);
        $this->assertDatabaseHas('material_movements', [
            'type' => 'received',
            'quantity_delta' => 10,
        ]);
    }

    public function test_next_batch_gets_next_number(): void
    {
        $payload = [
            'material_id' => $this->material->id,
            'quantity' => 5,
            'location_id' => $this->shelf->id,
        ];

        $this->postJson('/api/batches/receive-material', $payload)->assertJsonPath('batch_code', 'BL-0001');
        $this->postJson('/api/batches/receive-material', $payload)->assertJsonPath('batch_code', 'BL-0002');
    }

    public function test_receiving_into_existing_batch_increases_quantity(): void
    {
        $batchId = $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
        ])->json('id');

        $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 4,
            'location_id' => $this->shelf->id,
            'target_batch_id' => $batchId,
        ])->assertCreated()->assertJsonPath('quantity', 14);

        $this->assertDatabaseCount('material_batches', 1);
        $this->assertDatabaseCount('material_movements', 2);
    }

    public function test_receiving_waste_creates_batch_with_waste_prefix(): void
    {
        $this->postJson('/api/batches/receive-waste', [
            'quantity' => 3,
            'weight' => 12.5,
            'location_id' => $this->shelf->id,
        ])->assertCreated()
            ->assertJsonPath('batch_code', 'ODP-0001')
            ->assertJsonPath('type', MaterialBatch::TYPE_WASTE);
    }

    public function test_suggest_finds_existing_batch_on_the_same_shelf(): void
    {
        $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
        ]);

        // Trasa batches/suggest musi byc zadeklarowana przed batches/{batchCode}.
        $this->getJson('/api/batches/suggest?type=material&material_id='.$this->material->id.'&location_id='.$this->shelf->id)
            ->assertOk()
            ->assertJsonPath('batch.batch_code', 'BL-0001');
    }

    public function test_receive_validation_rejects_wrong_data(): void
    {
        $this->postJson('/api/batches/receive-material', [
            'material_id' => 999,
            'quantity' => 0,
            'location_id' => $this->shelf->id,
        ])->assertStatus(422)
            ->assertJsonValidationErrors(['material_id', 'quantity']);

        $this->assertDatabaseCount('material_batches', 0);
        $this->assertDatabaseCount('material_movements', 0);
    }

    public function test_batch_list_contains_full_location_path(): void
    {
        $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
        ]);

        $response = $this->getJson('/api/batches')
            ->assertOk()
            ->assertJsonPath('0.current_location.full_path', 'Sektor 1 → Regał 1 → Półka 1');

        // Zagniezdzona relacja parent nie jest wysylana - aplikacja potrzebuje tylko full_path.
        $response->assertJsonMissingPath('0.current_location.parent');
    }

    public function test_batch_list_uses_constant_number_of_queries(): void
    {
        // 20 partii na 10 roznych polkach w 5 regalach.
        $sector = WarehouseLocation::create(['code' => 'S2', 'name' => 'Sektor 2', 'type' => 'sektor']);

        foreach (range(1, 5) as $r) {
            $rack = WarehouseLocation::create(['code' => "S2-R$r", 'name' => "Regał $r", 'type' => 'regal', 'parent_id' => $sector->id]);

            foreach (range(1, 2) as $p) {
                $shelf = WarehouseLocation::create(['code' => "S2-R$r-P$p", 'name' => "Półka $p", 'type' => 'polka', 'parent_id' => $rack->id]);

                foreach (range(1, 2) as $i) {
                    $this->postJson('/api/batches/receive-material', [
                        'material_id' => $this->material->id,
                        'quantity' => $i,
                        'location_id' => $shelf->id,
                    ]);
                }
            }
        }

        DB::enableQueryLog();
        $this->getJson('/api/batches')->assertOk()->assertJsonCount(20);
        $queries = count(DB::getQueryLog());

        // Partie, materialy i trzy poziomy lokalizacji - liczba zapytan nie zalezy od liczby polek.
        $this->assertLessThanOrEqual(5, $queries);
    }

    public function test_batch_can_be_found_by_code(): void
    {
        $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
        ]);

        $this->getJson('/api/batches/BL-0001')
            ->assertOk()
            ->assertJsonPath('quantity', 10)
            ->assertJsonCount(1, 'movements');

        $this->getJson('/api/batches/XX-9999')->assertNotFound();
    }
}
