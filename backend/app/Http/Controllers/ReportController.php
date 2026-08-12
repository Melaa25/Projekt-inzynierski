<?php

namespace App\Http\Controllers;

use App\Models\MaterialBatch;
use App\Models\MaterialMovement;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\StreamedResponse;

class ReportController extends Controller
{
    public function stockCsv(): StreamedResponse
    {
        $batches = MaterialBatch::with(['material', 'currentLocation'])
            ->orderBy('id')
            ->get();

        $filename = 'stan_magazynowy_' . now()->format('Y_m_d_His') . '.csv';

        return response()->streamDownload(function () use ($batches) {
            $handle = fopen('php://output', 'w');
            fwrite($handle, "\xEF\xBB\xBF"); // BOM, zeby Excel poprawnie pokazal polskie znaki

            fputcsv($handle, [
                'Kod partii',
                'Typ',
                'Materiał',
                'Ilość',
                'Waga łączna (kg)',
                'Lokalizacja',
                'Status',
                'Data utworzenia',
            ], ';');

            foreach ($batches as $batch) {
                fputcsv($handle, [
                    $batch->batch_code,
                    $batch->type === 'waste' ? 'Odpad' : 'Materiał',
                    $batch->material?->name ?? '-',
                    $batch->quantity,
                    $batch->total_weight ?? '',
                    $batch->currentLocation?->name ?? '-',
                    $batch->status,
                    $batch->created_at?->format('Y-m-d H:i'),
                ], ';');
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ]);
    }

    public function movementsCsv(Request $request): StreamedResponse
    {
        $query = MaterialMovement::with(['batch.material', 'batch.currentLocation', 'user']);

        if ($request->filled('from')) {
            $query->whereDate('created_at', '>=', $request->query('from'));
        }

        if ($request->filled('to')) {
            $query->whereDate('created_at', '<=', $request->query('to'));
        }

        if ($request->filled('type')) {
            $query->where('type', $request->query('type'));
        }

        $movements = $query->orderBy('created_at')->get();

        $filename = 'historia_ruchow_' . now()->format('Y_m_d_His') . '.csv';

        return response()->streamDownload(function () use ($movements) {
            $handle = fopen('php://output', 'w');
            fwrite($handle, "\xEF\xBB\xBF");

            fputcsv($handle, [
                'Data',
                'Typ ruchu',
                'Kod partii',
                'Materiał',
                'Zmiana ilości',
                'Cel wydania',
                'Lokalizacja',
                'Użytkownik',
                'Uwagi',
            ], ';');

            foreach ($movements as $movement) {
                fputcsv($handle, [
                    $movement->created_at?->format('Y-m-d H:i'),
                    $movement->type,
                    $movement->batch?->batch_code ?? '-',
                    $movement->batch?->material?->name
                        ?? ($movement->batch?->type === 'waste' ? 'Odpad' : '-'),
                    $movement->quantity_delta,
                    $movement->destination ?? '',
                    $movement->batch?->currentLocation?->name ?? '-',
                    $movement->user?->name ?? '-',
                    $movement->note ?? '',
                ], ';');
            }

            fclose($handle);
        }, $filename, [
            'Content-Type' => 'text/csv; charset=UTF-8',
        ]);
    }
}