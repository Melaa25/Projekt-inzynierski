<?php

use App\Http\Controllers\MaterialController;
use Illuminate\Support\Facades\Route;

Route::apiResource('materials', MaterialController::class);