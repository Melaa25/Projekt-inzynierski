<?php

namespace Tests\Feature;

use App\Models\User;
use App\Models\WarehouseLocation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class LocationTest extends TestCase
{
    use RefreshDatabase;

    protected function setUp(): void
    {
        parent::setUp();

        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_MANAGER]));
    }

    public function test_manager_builds_sector_rack_shelf_hierarchy(): void
    {
        $sectorId = $this->postJson('/api/locations', [
            'name' => 'Sektor A',
            'type' => 'sektor',
        ])->assertCreated()->json('id');

        $rackId = $this->postJson('/api/locations', [
            'name' => 'Regał 1',
            'type' => 'regal',
            'parent_id' => $sectorId,
        ])->assertCreated()->json('id');

        $this->postJson('/api/locations', [
            'name' => 'Półka 3',
            'type' => 'polka',
            'parent_id' => $rackId,
        ])->assertCreated()
            ->assertJsonPath('full_path', 'Sektor A → Regał 1 → Półka 3');
    }

    public function test_shelf_must_belong_to_rack(): void
    {
        $sector = WarehouseLocation::create(['name' => 'Sektor A', 'type' => 'sektor']);

        $this->postJson('/api/locations', [
            'name' => 'Półka 1',
            'type' => 'polka',
            'parent_id' => $sector->id,
        ])->assertStatus(422)
            ->assertJsonPath('message', 'Półka musi być przypisana do regału.');
    }

    public function test_sector_cannot_have_parent(): void
    {
        $sector = WarehouseLocation::create(['name' => 'Sektor A', 'type' => 'sektor']);

        $this->postJson('/api/locations', [
            'name' => 'Sektor B',
            'type' => 'sektor',
            'parent_id' => $sector->id,
        ])->assertStatus(422);
    }

    public function test_unknown_location_type_is_rejected(): void
    {
        $this->postJson('/api/locations', [
            'name' => 'Strefa',
            'type' => 'strefa',
        ])->assertStatus(422)->assertJsonValidationErrors('type');
    }

    public function test_worker_cannot_create_locations(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_WORKER]));

        $this->postJson('/api/locations', [
            'name' => 'Sektor A',
            'type' => 'sektor',
        ])->assertForbidden();
    }
}
