<?php

namespace App\Http\Controllers;

use App\Http\Requests\StoreMaterialRequest;
use App\Http\Requests\UpdateMaterialRequest;
use App\Models\Material;
use Illuminate\Http\JsonResponse;

class MaterialController extends Controller
{
    public function index(): JsonResponse
    {
        $materials = Material::orderBy('id', 'desc')->get();

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