<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class Material extends Model
{
    protected $fillable = [
        'name',
        'weight',
        'length',
        'location',
    ];

    protected static function booted(): void
    {
        static::creating(function (Material $material): void {
            $material->serial_number = static::generateSerialNumber($material->name);
        });
    }

    private static function generateSerialNumber(string $name): string
    {
        $prefix = static::buildPrefix($name);

        $lastSerialForPrefix = static::query()
            ->where('serial_number', 'like', $prefix.'-%')
            ->orderByDesc('serial_number')
            ->value('serial_number');

        $nextNumber = 1;
        if (is_string($lastSerialForPrefix) && preg_match('/^(?:[A-Z]{2})-(\d+)$/', $lastSerialForPrefix, $matches) === 1) {
            $nextNumber = ((int) $matches[1]) + 1;
        }

        return sprintf('%s-%04d', $prefix, $nextNumber);
    }

    private static function buildPrefix(string $name): string
    {
        $normalized = Str::upper(Str::ascii($name));
        $lettersOnly = preg_replace('/[^A-Z]/', '', $normalized) ?? '';

        if ($lettersOnly === '') {
            return 'XX';
        }

        if (strlen($lettersOnly) === 1) {
            return $lettersOnly.'X';
        }

        return substr($lettersOnly, 0, 2);
    }
}
