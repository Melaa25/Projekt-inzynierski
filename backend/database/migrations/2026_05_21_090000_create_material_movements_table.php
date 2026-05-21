<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('material_movements', function (Blueprint $table) {
            $table->id();
            $table->foreignId('material_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('type', 20);
            $table->string('destination')->nullable();
            $table->text('note')->nullable();
            $table->string('previous_status', 50)->nullable();
            $table->string('new_status', 50);
            $table->foreignId('previous_location_id')->nullable()->constrained('warehouse_locations')->nullOnDelete();
            $table->foreignId('new_location_id')->nullable()->constrained('warehouse_locations')->nullOnDelete();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('material_movements');
    }
};
