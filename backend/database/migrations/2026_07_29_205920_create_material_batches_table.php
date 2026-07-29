<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('material_batches', function (Blueprint $table) {
            $table->id();
            $table->string('type', 20)->default('material');
            $table->foreignId('material_id')->nullable()->constrained('materials')->cascadeOnDelete();
            $table->string('batch_code')->unique();
            $table->unsignedInteger('quantity')->default(0);
            $table->decimal('total_weight', 10, 3)->nullable();
            $table->foreignId('current_location_id')->nullable()->constrained('warehouse_locations')->nullOnDelete();
            $table->string('status', 20)->default('in_stock');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('material_batches');
    }
};