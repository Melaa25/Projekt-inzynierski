<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreMaterialRequest;
use App\Http\Requests\UpdateMaterialRequest;
use App\Models\Material;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MaterialController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $query = Material::query();

        $search = trim((string) $request->query('search', ''));
        if ($search !== '') {
            $query->where('name', 'like', '%'.$search.'%');
        }

        $materials = $query->orderBy('name')->get();

        return response()->json($materials);
    }

    public function store(StoreMaterialRequest $request): JsonResponse
    {
        $material = Material::create($request->validated());

        return response()->json($material, 201);
    }

    public function show(Material $material): JsonResponse
    {
        return response()->json($material);
    }

    public function update(UpdateMaterialRequest $request, Material $material): JsonResponse
    {
        $material->update($request->validated());

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