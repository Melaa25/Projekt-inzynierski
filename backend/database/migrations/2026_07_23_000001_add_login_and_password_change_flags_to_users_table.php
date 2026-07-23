<?php

use App\Models\User;
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
        Schema::table('users', function (Blueprint $table): void {
            $table->string('login')->nullable()->unique()->after('name');
            $table->boolean('must_change_password')->default(true)->after('password');
        });

        $users = User::query()->orderBy('id')->get();

        foreach ($users as $user) {
            $user->update([
                'login' => User::buildLoginFromName($user->name, $user->id),
                'must_change_password' => true,
            ]);
        }
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::table('users', function (Blueprint $table): void {
            $table->dropColumn(['login', 'must_change_password']);
        });
    }
};