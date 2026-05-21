<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreMaterialMovementRequest;
use App\Models\Material;
use App\Models\MaterialMovement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MaterialMovementController extends Controller
{
    public function store(StoreMaterialMovementRequest $request, Material $material): JsonResponse
    {
        $data = $request->validated();
        $user = $request->user();

        $previousStatus = $material->status;
        $previousLocationId = $material->current_location_id;

        $newStatus = $data['type'] === 'received' ? 'in_stock' : 'issued';
        $newLocationId = $data['type'] === 'received'
            ? ($data['new_location_id'] ?? $material->current_location_id)
            : null;

        $material->update([
            'status' => $newStatus,
            'current_location_id' => $newLocationId,
        ]);

        $movement = MaterialMovement::create([
            'material_id' => $material->id,
            'user_id' => $user?->id,
            'type' => $data['type'],
            'destination' => $data['destination'] ?? null,
            'note' => $data['note'] ?? null,
            'previous_status' => $previousStatus,
            'new_status' => $newStatus,
            'previous_location_id' => $previousLocationId,
            'new_location_id' => $newLocationId,
        ]);

        $material->load('currentLocation');

        return response()->json([
            'movement' => $movement,
            'material' => $material,
        ], 201);
    }
}
