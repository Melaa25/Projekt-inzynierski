<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Str;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'login', 'email', 'password', 'role', 'must_change_password'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    public const ROLE_ADMIN = 'admin';
    public const ROLE_MANAGER = 'kierownik';
    public const ROLE_WORKER = 'pracownik';

    public const ALLOWED_ROLES = [
        self::ROLE_ADMIN,
        self::ROLE_MANAGER,
        self::ROLE_WORKER,
    ];

    public static function buildLoginFromName(string $name, ?int $ignoreUserId = null): string
    {
        $parts = preg_split('/\s+/', trim($name), -1, PREG_SPLIT_NO_EMPTY) ?: [];
        $firstName = $parts[0] ?? 'uzytkownik';
        $surname = $parts[count($parts) - 1] ?? $firstName;

        $initial = preg_replace('/[^a-z0-9]/', '', Str::lower(Str::ascii(substr($firstName, 0, 1)))) ?: 'u';
        $surnamePart = preg_replace('/[^a-z0-9]/', '', Str::lower(Str::ascii($surname))) ?: 'zytkownik';
        $baseLogin = $initial . '.' . $surnamePart;

        $login = $baseLogin;
        $suffix = 2;

        while (static::query()
            ->where('login', $login)
            ->when($ignoreUserId !== null, fn ($query) => $query->where('id', '!=', $ignoreUserId))
            ->exists()) {
            $login = $baseLogin . $suffix;
            $suffix++;
        }

        return $login;
    }

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'must_change_password' => 'boolean',
        ];
    }

    public function hasRole(string ...$roles): bool
    {
        return in_array($this->role, $roles, true);
    }
}
