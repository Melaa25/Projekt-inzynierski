<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class RoleAccessTest extends TestCase
{
    use RefreshDatabase;

    private array $newMaterial = [
        'name' => 'Blacha DC01',
        'weight' => 25.5,
        'length' => 2000,
        'thickness' => 2,
    ];

    public function test_worker_cannot_add_material_to_catalog(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_WORKER]));

        $this->postJson('/api/materials', $this->newMaterial)
            ->assertForbidden()
            ->assertJsonPath('message', 'Brak uprawnien do wykonania tej operacji.');

        $this->assertDatabaseCount('materials', 0);
    }

    public function test_manager_can_add_material_to_catalog(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_MANAGER]));

        $this->postJson('/api/materials', $this->newMaterial)->assertCreated();

        $this->assertDatabaseHas('materials', ['name' => 'Blacha DC01']);
    }

    public function test_worker_can_read_catalog(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_WORKER]));

        $this->getJson('/api/materials')->assertOk();
        $this->getJson('/api/locations')->assertOk();
    }

    public function test_only_admin_can_manage_users(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_WORKER]));
        $this->getJson('/api/users')->assertForbidden();

        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_MANAGER]));
        $this->getJson('/api/users')->assertForbidden();

        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_ADMIN]));
        $this->getJson('/api/users')->assertOk();
    }

    public function test_admin_creates_user_with_generated_login_and_forced_password_change(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_ADMIN]));

        $this->postJson('/api/users', [
            'name' => 'Jan Kowalski',
            'email' => 'jan.kowalski@example.com',
            'password' => 'startowe',
            'role' => User::ROLE_WORKER,
        ])->assertCreated()->assertJsonPath('login', 'j.kowalski');

        $this->assertDatabaseHas('users', [
            'login' => 'j.kowalski',
            'must_change_password' => true,
        ]);
    }

    public function test_user_role_must_be_one_of_allowed_roles(): void
    {
        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_ADMIN]));

        $this->postJson('/api/users', [
            'name' => 'Jan Kowalski',
            'email' => 'jan.kowalski@example.com',
            'password' => 'startowe',
            'role' => 'superuser',
        ])->assertStatus(422)->assertJsonValidationErrors('role');
    }
}
