<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    public function run(): void
    {
        $singleAdminMode = filter_var(env('SEED_SINGLE_ADMIN', false), FILTER_VALIDATE_BOOLEAN);

        User::updateOrCreate(
            ['email' => 'admin@admin.pl'],
            [
                'name' => 'Administrator',
                'login' => 'admin',
                'password' => 'admin123',
                'role' => User::ROLE_ADMIN,
                'must_change_password' => ! $singleAdminMode,
            ],
        );

        if ($singleAdminMode) {
            return;
        }

        User::updateOrCreate(
            ['email' => 'kierownik@example.com'],
            [
                'name' => 'Kierownik',
                'login' => 'kierownik',
                'password' => 'kierownik123',
                'role' => User::ROLE_MANAGER,
                'must_change_password' => true,
            ],
        );

        User::updateOrCreate(
            ['email' => 'pracownik@example.com'],
            [
                'name' => 'Pracownik',
                'login' => 'pracownik',
                'password' => 'pracownik123',
                'role' => User::ROLE_WORKER,
                'must_change_password' => true,
            ],
        );
    }
}