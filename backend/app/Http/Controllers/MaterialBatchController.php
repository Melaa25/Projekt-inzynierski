<?php

namespace App\Http\Controllers;

use App\Http\Requests\IssueMaterialBatchRequest;
use App\Http\Requests\ReceiveMaterialBatchRequest;
use App\Http\Requests\ReceiveWasteBatchRequest;
use App\Http\Requests\UpdateMaterialBatchStatusRequest;
use App\Models\MaterialBatch;
use App\Models\MaterialMovement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class MaterialBatchController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = MaterialBatch::with(['material', 'currentLocation']);

        $type = $request->query('type');
        if ($type) {
            $query->where('type', $type);
        }

        $status = $request->query('status');
        if ($status) {
            $query->where('status', $status);
        }

        $locationId = $request->query('location_id');
        if (is_numeric($locationId)) {
            $query->where('current_location_id', (int) $locationId);
        }

        $search = trim((string) $request->query('search', ''));
        if ($search !== '') {
            $query->where(function ($builder) use ($search): void {
                $builder->where('batch_code', 'like', '%'.$search.'%')
                    ->orWhereHas('material', function ($materialQuery) use ($search): void {
                        $materialQuery->where('name', 'like', '%'.$search.'%');
                    })
                    ->orWhereHas('currentLocation', function ($locationQuery) use ($search): void {
                        $locationQuery->where('name', 'like', '%'.$search.'%')
                            ->orWhere('code', 'like', '%'.$search.'%');
                    });
            });
        }

        $batches = $query->orderBy('id', 'desc')->get();

        return response()->json($batches);
    }

    public function show(string $batchCode): JsonResponse
    {
        $batch = MaterialBatch::with(['material', 'currentLocation', 'movements.user'])
            ->where('batch_code', $batchCode)
            ->firstOrFail();

        return response()->json($batch);
    }

    public function suggestExisting(Request $request): JsonResponse
    {
        $data = $request->validate([
            'material_id' => ['nullable', 'integer', 'exists:materials,id'],
            'type' => ['required', 'string', 'in:material,waste'],
            'location_id' => ['required', 'integer', 'exists:warehouse_locations,id'],
        ]);

        $existing = MaterialBatch::findActiveForReceiving(
            $data['material_id'] ?? null,
            $data['type'],
            $data['location_id'],
        );

        if ($existing === null) {
            return response()->json(['batch' => null]);
        }

        $existing->load(['material', 'currentLocation']);

        return response()->json(['batch' => $existing]);
    }

    public function receiveMaterial(ReceiveMaterialBatchRequest $request): JsonResponse
    {
        $data = $request->validated();

        $batch = DB::transaction(function () use ($data, $request) {
            $targetBatch = null;

            if (! empty($data['target_batch_id'])) {
                $targetBatch = MaterialBatch::query()
                    ->where('id', $data['target_batch_id'])
                    ->where('type', MaterialBatch::TYPE_MATERIAL)
                    ->where('material_id', $data['material_id'])
                    ->where('current_location_id', $data['location_id'])
                    ->where('status', MaterialBatch::STATUS_IN_STOCK)
                    ->first();
            }

            if ($targetBatch !== null) {
                $targetBatch->increment('quantity', $data['quantity']);
                $batch = $targetBatch->fresh();
            } else {
                $batch = MaterialBatch::create([
                    'type' => MaterialBatch::TYPE_MATERIAL,
                    'material_id' => $data['material_id'],
                    'quantity' => $data['quantity'],
                    'current_location_id' => $data['location_id'],
                    'status' => MaterialBatch::STATUS_IN_STOCK,
                ]);
            }

            MaterialMovement::create([
                'material_batch_id' => $batch->id,
                'user_id' => $request->user()?->id,
                'type' => 'received',
                'quantity_delta' => $data['quantity'],
                'note' => $data['note'] ?? null,
                'previous_status' => MaterialBatch::STATUS_IN_STOCK,
                'new_status' => MaterialBatch::STATUS_IN_STOCK,
                'previous_location_id' => $data['location_id'],
                'new_location_id' => $data['location_id'],
            ]);

            return $batch;
        });

        $batch->load(['material', 'currentLocation']);

        return response()->json($batch, 201);
    }

    public function receiveWaste(ReceiveWasteBatchRequest $request): JsonResponse
    {
        $data = $request->validated();

        $batch = DB::transaction(function () use ($data, $request) {
            $targetBatch = null;

            if (! empty($data['target_batch_id'])) {
                $targetBatch = MaterialBatch::query()
                    ->where('id', $data['target_batch_id'])
                    ->where('type', MaterialBatch::TYPE_WASTE)
                    ->where('current_location_id', $data['location_id'])
                    ->where('status', MaterialBatch::STATUS_IN_STOCK)
                    ->first();
            }

            if ($targetBatch !== null) {
                $targetBatch->increment('quantity', $data['quantity']);
                if (! empty($data['weight'])) {
                    $targetBatch->increment('total_weight', $data['weight']);
                }
                $batch = $targetBatch->fresh();
            } else {
                $batch = MaterialBatch::create([
                    'type' => MaterialBatch::TYPE_WASTE,
                    'material_id' => null,
                    'quantity' => $data['quantity'],
                    'total_weight' => $data['weight'] ?? null,
                    'current_location_id' => $data['location_id'],
                    'status' => MaterialBatch::STATUS_IN_STOCK,
                ]);
            }

            MaterialMovement::create([
                'material_batch_id' => $batch->id,
                'user_id' => $request->user()?->id,
                'type' => 'received',
                'quantity_delta' => $data['quantity'],
                'note' => $data['note'] ?? null,
                'previous_status' => MaterialBatch::STATUS_IN_STOCK,
                'new_status' => MaterialBatch::STATUS_IN_STOCK,
                'previous_location_id' => $data['location_id'],
                'new_location_id' => $data['location_id'],
            ]);

            return $batch;
        });

        $batch->load('currentLocation');

        return response()->json($batch, 201);
    }

    public function issue(IssueMaterialBatchRequest $request, MaterialBatch $batch): JsonResponse
    {
        $data = $request->validated();

        if ($data['quantity'] > $batch->quantity) {
            return response()->json([
                'message' => 'Ilość do wydania przekracza dostępną ilość w partii.',
            ], 422);
        }

        DB::transaction(function () use ($data, $batch, $request): void {
            $batch->decrement('quantity', $data['quantity']);

            MaterialMovement::create([
                'material_batch_id' => $batch->id,
                'user_id' => $request->user()?->id,
                'type' => 'issued',
                'quantity_delta' => -$data['quantity'],
                'destination' => $data['destination'] ?? null,
                'note' => $data['note'] ?? null,
                'previous_status' => $batch->status,
                'new_status' => $batch->status,
                'previous_location_id' => $batch->current_location_id,
                'new_location_id' => $batch->current_location_id,
            ]);
        });

        $batch->refresh()->load(['material', 'currentLocation']);

        return response()->json($batch);
    }

    public function updateStatus(UpdateMaterialBatchStatusRequest $request, MaterialBatch $batch): JsonResponse
    {
        $data = $request->validated();
        $previousStatus = $batch->status;

        DB::transaction(function () use ($data, $batch, $request, $previousStatus): void {
            $batch->update(['status' => $data['status']]);

            MaterialMovement::create([
                'material_batch_id' => $batch->id,
                'user_id' => $request->user()?->id,
                'type' => 'status_change',
                'quantity_delta' => 0,
                'note' => $data['note'] ?? null,
                'previous_status' => $previousStatus,
                'new_status' => $data['status'],
                'previous_location_id' => $batch->current_location_id,
                'new_location_id' => $batch->current_location_id,
            ]);
        });

        $batch->refresh()->load(['material', 'currentLocation']);

        return response()->json($batch);
    }

    public function destroy(MaterialBatch $batch): JsonResponse
    {
        $batch->delete();

        return response()->json([
            'message' => 'Batch deleted successfully',
        ]);
    }
}