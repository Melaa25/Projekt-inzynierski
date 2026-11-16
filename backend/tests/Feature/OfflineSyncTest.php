<?php

namespace Tests\Feature;

use App\Models\Material;
use App\Models\MaterialMovement;
use App\Models\User;
use App\Models\WarehouseLocation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

/**
 * Testy zachowania serwera przy synchronizacji operacji wykonanych offline.
 * Dane zadan wygladaja tak samo, jak te wysylane z kolejki w aplikacji mobilnej.
 */
class OfflineSyncTest extends TestCase
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

        $this->shelf = WarehouseLocation::create(['code' => 'S1-R1-P1', 'name' => 'Półka 1', 'type' => 'polka']);
    }

    public function test_same_operation_sent_twice_is_saved_only_once(): void
    {
        $payload = [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
            'client_uuid' => '7f6c2a8e-1111-4c1e-9d55-000000000001',
            'client_operation_id' => '0b8e5f3a-2222-4a8b-8c11-000000000001',
            'performed_at' => '2026-11-10T07:15:00Z',
        ];

        $first = $this->postJson('/api/batches/receive-material', $payload)->assertCreated();

        // Np. odpowiedz na pierwsze zadanie nie dotarla do telefonu i kolejka wyslala je ponownie.
        $second = $this->postJson('/api/batches/receive-material', $payload)->assertOk();

        $this->assertSame($first->json('id'), $second->json('id'));
        $this->assertDatabaseCount('material_batches', 1);
        $this->assertDatabaseCount('material_movements', 1);
        $this->assertSame(10, $second->json('quantity'));
    }

    public function test_repeated_issue_does_not_decrease_quantity_twice(): void
    {
        $batchId = $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
        ])->json('id');

        $issue = [
            'quantity' => 4,
            'client_operation_id' => '0b8e5f3a-2222-4a8b-8c11-000000000002',
        ];

        $this->postJson('/api/batches/'.$batchId.'/issue', $issue)->assertOk()->assertJsonPath('quantity', 6);
        $this->postJson('/api/batches/'.$batchId.'/issue', $issue)->assertOk()->assertJsonPath('quantity', 6);

        $this->assertSame(1, MaterialMovement::where('type', 'issued')->count());
    }

    public function test_batch_created_offline_can_be_addressed_by_client_uuid(): void
    {
        $clientUuid = '7f6c2a8e-1111-4c1e-9d55-000000000003';

        // 1. Przyjecie wykonane offline - partia ma tylko identyfikator z telefonu.
        $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
            'client_uuid' => $clientUuid,
            'client_operation_id' => '0b8e5f3a-2222-4a8b-8c11-000000000003',
        ])->assertCreated();

        // 2. Wydanie z tej samej partii, zapisane w kolejce pod adresem z client_uuid.
        $this->postJson('/api/batches/'.$clientUuid.'/issue', [
            'quantity' => 2,
            'client_operation_id' => '0b8e5f3a-2222-4a8b-8c11-000000000004',
        ])->assertOk()->assertJsonPath('quantity', 8);

        // 3. Zmiana statusu tej samej partii.
        $this->postJson('/api/batches/'.$clientUuid.'/status', [
            'status' => 'reserved',
            'client_operation_id' => '0b8e5f3a-2222-4a8b-8c11-000000000005',
        ])->assertOk()->assertJsonPath('status', 'reserved');
    }

    public function test_receiving_into_batch_created_offline_uses_target_batch_uuid(): void
    {
        $clientUuid = '7f6c2a8e-1111-4c1e-9d55-000000000006';

        $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
            'client_uuid' => $clientUuid,
        ])->assertCreated();

        $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 5,
            'location_id' => $this->shelf->id,
            'target_batch_uuid' => $clientUuid,
        ])->assertCreated()->assertJsonPath('quantity', 15);

        $this->assertDatabaseCount('material_batches', 1);
    }

    public function test_performed_at_from_phone_is_stored_in_history(): void
    {
        $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
            'client_operation_id' => '0b8e5f3a-2222-4a8b-8c11-000000000007',
            'performed_at' => '2026-11-10T07:15:00Z',
        ])->assertCreated();

        $movement = MaterialMovement::first();

        // Operacja wykonana offline ma zachowany czas z telefonu, a nie czas synchronizacji.
        $this->assertSame('2026-11-10 07:15:00', $movement->performed_at->utc()->format('Y-m-d H:i:s'));
        $this->assertTrue($movement->performed_at->lt($movement->created_at));
    }

    public function test_unknown_client_uuid_returns_not_found(): void
    {
        $this->postJson('/api/batches/nieistniejacy-uuid/issue', [
            'quantity' => 1,
        ])->assertNotFound();
    }
}
