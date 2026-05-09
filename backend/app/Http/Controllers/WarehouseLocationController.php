<?php

namespace App\Http\Controllers;

use App\Models\WarehouseLocation;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class WarehouseLocationController extends Controller
{
    public function index(): JsonResponse
    {
        $locations = WarehouseLocation::orderBy('name')->get();

        return response()->json($locations);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate([
            'code' => ['nullable', 'string', 'max:50'],
            'name' => ['required', 'string', 'max:255'],
            'type' => ['nullable', 'string', 'max:100'],
            'parent_id' => ['nullable', 'integer', 'exists:warehouse_locations,id'],
            'description' => ['nullable', 'string'],
        ]);

        $location = WarehouseLocation::create($data);

        return response()->json($location, 201);
    }

    public function show(WarehouseLocation $location): JsonResponse
    {
        return response()->json($location);
    }

    public function update(Request $request, WarehouseLocation $location): JsonResponse
    {
        $data = $request->validate([
            'code' => ['nullable', 'string', 'max:50'],
            'name' => ['required', 'string', 'max:255'],
            'type' => ['nullable', 'string', 'max:100'],
            'parent_id' => ['nullable', 'integer', 'exists:warehouse_locations,id'],
            'description' => ['nullable', 'string'],
        ]);

        $location->update($data);

        return response()->json($location);
    }

    public function destroy(WarehouseLocation $location): JsonResponse
    {
        $location->delete();

        return response()->json(['message' => 'Location deleted successfully']);
    }
}
