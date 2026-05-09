<?php

use App\Http\Controllers\MaterialController;
use App\Http\Controllers\WarehouseLocationController;
use Illuminate\Support\Facades\Route;

Route::apiResource('materials', MaterialController::class);
Route::apiResource('locations', WarehouseLocationController::class);