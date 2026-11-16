<?php

namespace Tests\Unit;

use App\Models\User;
use PHPUnit\Framework\TestCase;

/**
 * Test jednostkowy - sprawdza sama metode modelu, bez bazy danych i bez zapytan HTTP.
 */
class UserRoleTest extends TestCase
{
    public function test_user_has_role_from_given_list(): void
    {
        $manager = new User(['role' => User::ROLE_MANAGER]);

        $this->assertTrue($manager->hasRole(User::ROLE_ADMIN, User::ROLE_MANAGER));
        $this->assertTrue($manager->hasRole(User::ROLE_MANAGER));
    }

    public function test_user_does_not_have_role_outside_given_list(): void
    {
        $worker = new User(['role' => User::ROLE_WORKER]);

        $this->assertFalse($worker->hasRole(User::ROLE_ADMIN, User::ROLE_MANAGER));
        $this->assertFalse($worker->hasRole(User::ROLE_ADMIN));
    }

    public function test_role_comparison_is_exact(): void
    {
        // Rola zapisana inna wielkoscia liter nie daje uprawnien.
        $user = new User(['role' => 'Admin']);

        $this->assertFalse($user->hasRole(User::ROLE_ADMIN));
    }
}
