<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreMaterialRequest;
use App\Http\Requests\UpdateMaterialRequest;
use App\Models\Material;
use Illuminate\Http\Request;
use Illuminate\Http\JsonResponse;

class MaterialController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Material::with('currentLocation');

        $search = trim((string) $request->query('search', ''));
        if ($search !== '') {
            $query->where(function ($builder) use ($search): void {
                $builder->where('name', 'like', '%' . $search . '%')
                    ->orWhere('serial_number', 'like', '%' . $search . '%')
                    ->orWhere('location', 'like', '%' . $search . '%')
                    ->orWhereHas('currentLocation', function ($locationQuery) use ($search): void {
                        $locationQuery->where('name', 'like', '%' . $search . '%')
                            ->orWhere('code', 'like', '%' . $search . '%');
                    });
            });
        }

        $status = trim((string) $request->query('status', ''));
        if ($status !== '') {
            $query->where('status', $status);
        }

        $locationId = $request->query('location_id');
        if (is_numeric($locationId)) {
            $query->where('current_location_id', (int) $locationId);
        }

        $materials = $query->orderBy('id', 'desc')->get();

        return response()->json($materials);
    }

    public function store(StoreMaterialRequest $request): JsonResponse
    {
        $material = Material::create($request->validated());

        $material->load('currentLocation');

        return response()->json($material, 201);
    }

    public function show(Material $material): JsonResponse
    {
        $material->load('currentLocation');

        return response()->json($material);
    }

    public function update(UpdateMaterialRequest $request, Material $material): JsonResponse
    {
        $material->update($request->validated());

        $material->load('currentLocation');

        return response()->json($material);
    }

    public function destroy(Material $material): JsonResponse
    {
        $material->delete();

        return response()->json([
            'message' => 'Material deleted successfully',
        ]);
    }
}