<?php

namespace Tests\Feature;

use App\Models\Material;
use App\Models\User;
use App\Models\WarehouseLocation;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ReportTest extends TestCase
{
    use RefreshDatabase;

    private Material $material;
    private WarehouseLocation $shelf;

    protected function setUp(): void
    {
        parent::setUp();

        Sanctum::actingAs(User::factory()->create(['role' => User::ROLE_WORKER]));

        $this->material = Material::create([
            'name' => 'Blacha ocynkowana',
            'weight' => 25.5,
            'length' => 2000,
            'thickness' => 2,
        ]);

        $this->shelf = WarehouseLocation::create(['code' => 'S1-R1-P1', 'name' => 'Półka 1', 'type' => 'polka']);
    }

    public function test_stock_report_is_csv_readable_by_polish_excel(): void
    {
        $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
        ]);

        $response = $this->get('/api/reports/stock');
        $response->assertOk();
        $this->assertStringContainsString('text/csv', $response->headers->get('Content-Type'));

        $csv = $response->streamedContent();
        $lines = preg_split('/\r?\n/', trim($csv));

        // Znacznik BOM na poczatku pliku i srednik jako separator.
        $this->assertStringStartsWith("\xEF\xBB\xBF", $csv);
        $this->assertStringContainsString(';', $lines[0]);
        $this->assertCount(2, $lines);
        $this->assertStringContainsString('BL-0001', $lines[1]);
        $this->assertStringContainsString('Półka 1', $lines[1]);
    }

    public function test_movements_report_is_filtered_by_operation_time(): void
    {
        // Operacja wykonana offline 10 listopada, zsynchronizowana pozniej.
        $this->postJson('/api/batches/receive-material', [
            'material_id' => $this->material->id,
            'quantity' => 10,
            'location_id' => $this->shelf->id,
            'performed_at' => '2026-11-10T07:15:00Z',
        ]);

        $csvForThatDay = $this->get('/api/reports/movements?from=2026-11-10&to=2026-11-10')->streamedContent();
        $csvForOtherDay = $this->get('/api/reports/movements?from=2026-11-11&to=2026-11-11')->streamedContent();

        $this->assertCount(2, preg_split('/\r?\n/', trim($csvForThatDay)));
        $this->assertCount(1, preg_split('/\r?\n/', trim($csvForOtherDay)));

        // Godzina w raporcie jest w czasie polskim (07:15 UTC = 08:15 w listopadzie).
        $this->assertStringContainsString('2026-11-10 08:15', $csvForThatDay);
    }

    public function test_report_requires_login(): void
    {
        $this->app['auth']->forgetGuards();
        $this->app['auth']->guard('sanctum')->forgetUser();

        $this->getJson('/api/reports/stock')->assertUnauthorized();
    }
}
