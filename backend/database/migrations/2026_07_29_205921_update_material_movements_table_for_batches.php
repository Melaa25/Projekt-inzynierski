<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('material_movements', function (Blueprint $table) {
            $table->foreignId('material_batch_id')->nullable()->after('id')->constrained('material_batches')->cascadeOnDelete();
            $table->integer('quantity_delta')->default(0)->after('type');
        });

        Schema::table('material_movements', function (Blueprint $table) {
            $table->dropForeign(['material_id']);
            $table->dropColumn('material_id');
        });
    }

    public function down(): void
    {
        Schema::table('material_movements', function (Blueprint $table) {
            $table->foreignId('material_id')->nullable()->after('id')->constrained('materials')->cascadeOnDelete();
        });

        Schema::table('material_movements', function (Blueprint $table) {
            $table->dropForeign(['material_batch_id']);
            $table->dropColumn(['material_batch_id', 'quantity_delta']);
        });
    }
};