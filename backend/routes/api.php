<?php

use App\Http\Controllers\AuthController;
use App\Http\Controllers\MaterialMovementController;
use App\Http\Controllers\MaterialController;
use App\Http\Controllers\UserController;
use App\Http\Controllers\WarehouseLocationController;
use Illuminate\Support\Facades\Route;

Route::post('auth/login', [AuthController::class, 'login']);

Route::middleware('auth:sanctum')->group(function (): void {
	Route::get('auth/me', [AuthController::class, 'me']);
	Route::post('auth/logout', [AuthController::class, 'logout']);

	Route::get('materials', [MaterialController::class, 'index']);
	Route::get('materials/{material}', [MaterialController::class, 'show']);
	Route::post('materials/{material}/movements', [MaterialMovementController::class, 'store']);
	Route::get('movements', [MaterialMovementController::class, 'index']);

	Route::get('locations', [WarehouseLocationController::class, 'index']);
	Route::get('locations/{location}', [WarehouseLocationController::class, 'show']);

	Route::middleware('role:admin,kierownik')->group(function (): void {
		Route::post('materials', [MaterialController::class, 'store']);
		Route::put('materials/{material}', [MaterialController::class, 'update']);
		Route::delete('materials/{material}', [MaterialController::class, 'destroy']);

		Route::post('locations', [WarehouseLocationController::class, 'store']);
		Route::put('locations/{location}', [WarehouseLocationController::class, 'update']);
		Route::delete('locations/{location}', [WarehouseLocationController::class, 'destroy']);
	});

	Route::middleware('role:admin')->group(function (): void {
		Route::apiResource('users', UserController::class)
			->only(['index', 'store', 'update', 'destroy']);
	});
});