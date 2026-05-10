<?php

namespace Database\Seeders;

use App\Models\User;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        User::updateOrCreate(
            ['email' => 'admin@example.com'],
            [
                'name' => 'Administrator',
                'password' => 'password',
                'role' => User::ROLE_ADMIN,
            ],
        );

        User::updateOrCreate(
            ['email' => 'kierownik@example.com'],
            [
                'name' => 'Kierownik',
                'password' => 'password',
                'role' => User::ROLE_MANAGER,
            ],
        );

        User::updateOrCreate(
            ['email' => 'pracownik@example.com'],
            [
                'name' => 'Pracownik',
                'password' => 'password',
                'role' => User::ROLE_WORKER,
            ],
        );
    }
}
