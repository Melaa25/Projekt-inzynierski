<?php

namespace App\Http\Controllers;

use App\Models\WarehouseLocation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WarehouseLocationController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = WarehouseLocation::query()->with('parent.parent');

        if ($request->type) {
            $query->where('type', $request->type);
        }

        if ($request->has('parent_id')) {
            if ($request->parent_id == 'null' || $request->parent_id == null) {
                $query->whereNull('parent_id');
            } else {
                $query->where('parent_id', $request->parent_id);
            }
        }

        $locations = $query->withCount('children')->orderBy('name')->get();

        return response()->json($locations);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code' => 'nullable|string|max:50',
            'name' => 'required|string|max:255',
            'type' => 'required|string|in:sektor,regal,polka',
            'parent_id' => 'nullable|integer|exists:warehouse_locations,id',
            'description' => 'nullable|string',
        ]);

        if ($data['type'] == 'sektor' && !empty($data['parent_id'])) {
            return response()->json(['message' => 'Sektor nie może mieć rodzica.'], 422);
        }

        if ($data['type'] == 'regal') {
            $parent = WarehouseLocation::find($data['parent_id'] ?? null);
            if (!$parent || $parent->type != 'sektor') {
                return response()->json(['message' => 'Regał musi być przypisany do sektora.'], 422);
            }
        }

        if ($data['type'] == 'polka') {
            $parent = WarehouseLocation::find($data['parent_id'] ?? null);
            if (!$parent || $parent->type != 'regal') {
                return response()->json(['message' => 'Półka musi być przypisana do regału.'], 422);
            }
        }

        $location = WarehouseLocation::create($data);
        $location->load('parent.parent')->loadCount('children');

        return response()->json($location, 201);
    }

    public function show(WarehouseLocation $location): JsonResponse
    {
        $location->load('parent.parent')->loadCount('children');

        return response()->json($location);
    }

    public function update(Request $request, WarehouseLocation $location): JsonResponse
    {
        $data = $request->validate([
            'code' => 'nullable|string|max:50',
            'name' => 'required|string|max:255',
            'type' => 'required|string|in:sektor,regal,polka',
            'parent_id' => 'nullable|integer|exists:warehouse_locations,id',
            'description' => 'nullable|string',
        ]);

        if ($data['type'] != $location->type) {
            return response()->json(['message' => 'Nie można zmienić typu istniejącej lokalizacji.'], 422);
        }

        if (!empty($data['parent_id']) && $data['parent_id'] == $location->id) {
            return response()->json(['message' => 'Lokalizacja nie może być swoim własnym rodzicem.'], 422);
        }

        if ($data['type'] == 'sektor' && !empty($data['parent_id'])) {
            return response()->json(['message' => 'Sektor nie może mieć rodzica.'], 422);
        }

        if ($data['type'] == 'regal') {
            $parent = WarehouseLocation::find($data['parent_id'] ?? null);
            if (!$parent || $parent->type != 'sektor') {
                return response()->json(['message' => 'Regał musi być przypisany do sektora.'], 422);
            }
        }

        if ($data['type'] == 'polka') {
            $parent = WarehouseLocation::find($data['parent_id'] ?? null);
            if (!$parent || $parent->type != 'regal') {
                return response()->json(['message' => 'Półka musi być przypisana do regału.'], 422);
            }
        }

        $location->update($data);
        $location->load('parent.parent')->loadCount('children');

        return response()->json($location);
    }

    public function destroy(WarehouseLocation $location): JsonResponse
    {
        // Kasujemy od dolu, zeby nie zostawic regalow i polek bez rodzica.
        foreach ($location->children as $child) {
            $child->children()->delete();
        }

        $location->children()->delete();
        $location->delete();

        return response()->json(['message' => 'Location deleted successfully']);
    }
}