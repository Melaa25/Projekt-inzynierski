<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class WarehouseLocation extends Model
{
    protected $fillable = [
        'code',
        'name',
        'type',
        'parent_id',
        'description',
    ];

    protected $appends = [
        'full_path',
    ];

    public function parent()
    {
        return $this->belongsTo(self::class, 'parent_id');
    }

    public function children()
    {
        return $this->hasMany(self::class, 'parent_id');
    }

    public function batches()
    {
        return $this->hasMany(MaterialBatch::class, 'current_location_id');
    }

        public function getFullPathAttribute(): string
    {
        $parts = [$this->name];
        $node = $this->parent;
        $poziom = 0;

        // Magazyn ma trzy poziomy, wiec petla dluzsza niz 5 krokow oznacza bledne dane.
        while ($node && $poziom < 5) {
            $parts[] = $node->name;
            $node = $node->parent;
            $poziom++;
        }

        return implode(' → ', array_reverse($parts));
    }
}