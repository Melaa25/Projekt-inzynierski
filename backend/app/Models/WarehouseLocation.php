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

        while ($node) {
            $parts[] = $node->name;
            $node = $node->parent;
        }

        return implode(' → ', array_reverse($parts));
    }
}