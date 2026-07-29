<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('materials', function (Blueprint $table) {
            $table->dropColumn(['serial_number', 'location', 'status']);
        });

        Schema::table('materials', function (Blueprint $table) {
            $table->dropForeign(['current_location_id']);
            $table->dropColumn('current_location_id');
        });
    }

    public function down(): void
    {
        Schema::table('materials', function (Blueprint $table) {
            $table->string('serial_number')->unique()->nullable();
            $table->string('location')->nullable();
            $table->string('status')->default('in_stock');
            $table->foreignId('current_location_id')->nullable()->constrained('warehouse_locations')->nullOnDelete();
        });
    }
};