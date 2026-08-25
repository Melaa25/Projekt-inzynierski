<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('material_batches', function (Blueprint $table) {
            // Identyfikator nadany przez klienta jeszcze przed synchronizacja.
            $table->string('client_uuid', 64)->nullable()->unique()->after('batch_code');
        });

        Schema::table('material_movements', function (Blueprint $table) {
            // Klucz idempotencji - chroni przed zdublowaniem operacji przy ponownej wysylce.
            $table->string('client_operation_id', 64)->nullable()->unique()->after('id');
            // Rzeczywisty czas wykonania operacji na urzadzeniu (moze byc wczesniejszy niz created_at).
            $table->timestamp('performed_at')->nullable()->after('note');
        });
    }

    public function down(): void
    {
        Schema::table('material_batches', function (Blueprint $table) {
            $table->dropColumn('client_uuid');
        });

        Schema::table('material_movements', function (Blueprint $table) {
            $table->dropColumn(['client_operation_id', 'performed_at']);
        });
    }
};