<?php

namespace Database\Seeders;

use App\Models\Material;
use App\Models\MaterialBatch;
use App\Models\MaterialMovement;
use App\Models\User;
use App\Models\WarehouseLocation;
use Illuminate\Database\Seeder;

/**
 * Dane dla testow funkcjonalnych (Playwright) i wydajnosciowych (JMeter).
 * Uruchamiac TYLKO na bazie testowej:
 *   php artisan migrate:fresh --seed --seeder=TestEnvironmentSeeder
 *
 * Liczbe partii mozna zmienic zmienna srodowiskowa TEST_BATCH_COUNT (domyslnie 0).
 */
class TestEnvironmentSeeder extends Seeder
{
    public function run(): void
    {
        // Konta testowe - hasla sa jawne, bo baza jest tylko testowa.
        $admin = User::updateOrCreate(['login' => 'test.admin'], [
            'name' => 'Test Administrator',
            'email' => 'test.admin@example.com',
            'password' => 'Test1234!',
            'role' => User::ROLE_ADMIN,
            'must_change_password' => false,
        ]);

        User::updateOrCreate(['login' => 'test.kierownik'], [
            'name' => 'Test Kierownik',
            'email' => 'test.kierownik@example.com',
            'password' => 'Test1234!',
            'role' => User::ROLE_MANAGER,
            'must_change_password' => false,
        ]);

        User::updateOrCreate(['login' => 'test.pracownik'], [
            'name' => 'Test Pracownik',
            'email' => 'test.pracownik@example.com',
            'password' => 'Test1234!',
            'role' => User::ROLE_WORKER,
            'must_change_password' => false,
        ]);

        // Struktura jak w magazynie: 3 sektory x 7 regalow x 4 polki = 84 polki.
        $shelves = [];

        for ($s = 1; $s <= 3; $s++) {
            $sector = WarehouseLocation::create(['code' => "S$s", 'name' => "Sektor $s", 'type' => 'sektor']);

            for ($r = 1; $r <= 7; $r++) {
                $rack = WarehouseLocation::create([
                    'code' => "S$s-R$r",
                    'name' => "Regał $r",
                    'type' => 'regal',
                    'parent_id' => $sector->id,
                ]);

                for ($p = 1; $p <= 4; $p++) {
                    $shelves[] = WarehouseLocation::create([
                        'code' => "S$s-R$r-P$p",
                        'name' => "Półka S$s-R$r-P$p",
                        'type' => 'polka',
                        'parent_id' => $rack->id,
                    ]);
                }
            }
        }

        $names = [
            'Blacha DC01', 'Blacha ocynkowana', 'Blacha nierdzewna', 'Profil zamknięty', 'Kątownik',
            'Ceownik', 'Płaskownik', 'Rura stalowa', 'Pręt gładki', 'Siatka zgrzewana',
        ];

        $materials = [];

        foreach ($names as $i => $name) {
            $materials[] = Material::create([
                'name' => $name,
                'weight' => 20 + $i,
                'length' => 2000,
                'thickness' => 1 + $i % 4,
            ]);
        }

        // Partie do testow wydajnosciowych - kazda z jednym ruchem przyjecia.
        $count = (int) env('TEST_BATCH_COUNT', 0);

        for ($i = 0; $i < $count; $i++) {
            $isWaste = $i % 10 === 9;
            $shelf = $shelves[$i % count($shelves)];

            $batch = MaterialBatch::create([
                'type' => $isWaste ? MaterialBatch::TYPE_WASTE : MaterialBatch::TYPE_MATERIAL,
                'material_id' => $isWaste ? null : $materials[$i % count($materials)]->id,
                'quantity' => 5 + $i % 20,
                'total_weight' => $isWaste ? 10 + $i % 15 : null,
                'current_location_id' => $shelf->id,
                'status' => MaterialBatch::STATUS_IN_STOCK,
            ]);

            MaterialMovement::create([
                'material_batch_id' => $batch->id,
                'user_id' => $admin->id,
                'type' => 'received',
                'quantity_delta' => $batch->quantity,
                'performed_at' => now(),
                'previous_status' => MaterialBatch::STATUS_IN_STOCK,
                'new_status' => MaterialBatch::STATUS_IN_STOCK,
                'previous_location_id' => $shelf->id,
                'new_location_id' => $shelf->id,
            ]);
        }
    }
}
