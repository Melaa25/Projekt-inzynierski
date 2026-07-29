<?php

namespace App\Http\Controllers;

use App\Models\MaterialMovement;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MaterialMovementController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $type = $request->query('type');

        $query = MaterialMovement::with(['batch.material', 'batch.currentLocation', 'user', 'previousLocation', 'newLocation']);

        if ($type) {
            $query->where('type', $type);
        }

        $movements = $query->orderBy('created_at', 'desc')->paginate(50);

        return response()->json($movements);
    }
}