<?php

namespace Tests\Feature;

use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AuthTest extends TestCase
{
    use RefreshDatabase;

    public function test_user_can_log_in_with_correct_login_and_password(): void
    {
        User::factory()->create([
            'login' => 'j.kowalski',
            'password' => 'tajnehaslo',
            'role' => User::ROLE_WORKER,
        ]);

        $response = $this->postJson('/api/auth/login', [
            'login' => 'j.kowalski',
            'password' => 'tajnehaslo',
        ]);

        $response->assertOk()
            ->assertJsonStructure(['token', 'token_type', 'user' => ['id', 'login', 'role', 'must_change_password']])
            ->assertJsonPath('user.role', User::ROLE_WORKER);
    }

    public function test_login_fails_with_wrong_password(): void
    {
        User::factory()->create([
            'login' => 'j.kowalski',
            'password' => 'tajnehaslo',
        ]);

        $response = $this->postJson('/api/auth/login', [
            'login' => 'j.kowalski',
            'password' => 'zlehaslo',
        ]);

        $response->assertStatus(422)
            ->assertJsonMissing(['token_type' => 'Bearer']);
    }

    public function test_protected_endpoint_requires_token(): void
    {
        $this->getJson('/api/batches')->assertUnauthorized();
        $this->getJson('/api/auth/me')->assertUnauthorized();
    }

    public function test_ping_endpoint_works_without_token(): void
    {
        $this->getJson('/api/ping')
            ->assertOk()
            ->assertJson(['status' => 'ok']);
    }

    public function test_token_stops_working_after_logout(): void
    {
        $user = User::factory()->create();
        $token = $user->createToken('mobile-client')->plainTextToken;

        $this->withToken($token)->getJson('/api/auth/me')->assertOk();

        $this->withToken($token)->postJson('/api/auth/logout')->assertOk();

        // Po wylogowaniu token zostal usuniety z bazy.
        $this->assertDatabaseCount('personal_access_tokens', 0);

        // Resetujemy zapamietanego uzytkownika, zeby kolejne zapytanie przeszlo pelne uwierzytelnienie.
        $this->app['auth']->forgetGuards();

        $this->withToken($token)->getJson('/api/auth/me')->assertUnauthorized();
    }

    public function test_changing_password_clears_must_change_password_flag(): void
    {
        $user = User::factory()->create([
            'login' => 'a.nowak',
            'password' => 'startowe',
            'must_change_password' => true,
        ]);
        $token = $user->createToken('mobile-client')->plainTextToken;

        $this->withToken($token)->postJson('/api/auth/password', [
            'password' => 'nowehaslo1',
            'password_confirmation' => 'nowehaslo1',
        ])->assertOk()->assertJsonPath('must_change_password', false);

        $this->postJson('/api/auth/login', [
            'login' => 'a.nowak',
            'password' => 'nowehaslo1',
        ])->assertOk();
    }

    public function test_new_password_must_be_confirmed(): void
    {
        $user = User::factory()->create(['must_change_password' => true]);
        $token = $user->createToken('mobile-client')->plainTextToken;

        $this->withToken($token)->postJson('/api/auth/password', [
            'password' => 'nowehaslo1',
            'password_confirmation' => 'innehaslo',
        ])->assertStatus(422)->assertJsonValidationErrors('password');

        $this->assertTrue($user->fresh()->must_change_password);
    }
}
