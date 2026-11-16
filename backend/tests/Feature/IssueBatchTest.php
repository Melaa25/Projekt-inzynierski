<?php

namespace Tests\Feature;

use App\Models\Material;
use App\Models\MaterialBatch;
use App\Models\User;
use App\Models\WarehouseLocation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class IssueBatchTest extends TestCase
{
    use RefreshDatabase;

    private MaterialBatch $batch;

    protected function setUp(): void
    {
        parent::setUp();

        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_WORKER]));

        $material = Material::create([
            'name' => 'Blacha DC01',
            'weight' => 25.5,
            'length' => 2000,
            'thickness' => 2,
        ]);

        $shelf = WarehouseLocation::create(['code' => 'S1-R1-P1', 'name' => 'Półka 1', 'type' => 'polka']);

        $this->batch = MaterialBatch::create([
            'type' => MaterialBatch::TYPE_MATERIAL,
            'material_id' => $material->id,
            'quantity' => 10,
            'current_location_id' => $shelf->id,
            'status' => MaterialBatch::STATUS_IN_STOCK,
        ]);
    }

    public function test_issue_decreases_quantity_and_records_movement(): void
    {
        $this->postJson('/api/batches/'.$this->batch->id.'/issue', [
            'quantity' => 3,
            'destination' => 'Hala produkcyjna',
        ])->assertOk()->assertJsonPath('quantity', 7);

        $this->assertDatabaseHas('material_movements', [
            'material_batch_id' => $this->batch->id,
            'type' => 'issued',
            'quantity_delta' => -3,
            'destination' => 'Hala produkcyjna',
        ]);
    }

    public function test_cannot_issue_more_than_available(): void
    {
        $this->postJson('/api/batches/'.$this->batch->id.'/issue', [
            'quantity' => 11,
        ])->assertStatus(422)
            ->assertJsonPath('message', 'Ilość do wydania przekracza dostępną ilość w partii.');

        $this->assertSame(10, $this->batch->fresh()->quantity);
        $this->assertDatabaseCount('material_movements', 0);
    }

    public function test_whole_batch_can_be_issued(): void
    {
        $this->postJson('/api/batches/'.$this->batch->id.'/issue', [
            'quantity' => 10,
        ])->assertOk()->assertJsonPath('quantity', 0);
    }

    public function test_status_change_is_saved_in_history(): void
    {
        $this->postJson('/api/batches/'.$this->batch->id.'/status', [
            'status' => MaterialBatch::STATUS_DAMAGED,
            'note' => 'Wygięty arkusz',
        ])->assertOk()->assertJsonPath('status', MaterialBatch::STATUS_DAMAGED);

        $this->assertDatabaseHas('material_movements', [
            'material_batch_id' => $this->batch->id,
            'type' => 'status_change',
            'quantity_delta' => 0,
            'previous_status' => MaterialBatch::STATUS_IN_STOCK,
            'new_status' => MaterialBatch::STATUS_DAMAGED,
        ]);
    }

    public function test_unknown_status_is_rejected(): void
    {
        $this->postJson('/api/batches/'.$this->batch->id.'/status', [
            'status' => 'sold',
        ])->assertStatus(422)->assertJsonValidationErrors('status');

        $this->assertSame(MaterialBatch::STATUS_IN_STOCK, $this->batch->fresh()->status);
    }

    public function test_worker_cannot_delete_batch_but_manager_can(): void
    {
        $this->deleteJson('/api/batches/'.$this->batch->id)->assertForbidden();

        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_MANAGER]));

        $this->deleteJson('/api/batches/'.$this->batch->id)->assertOk();
        $this->assertDatabaseCount('material_batches', 0);
    }
}
