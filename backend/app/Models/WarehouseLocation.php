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
}