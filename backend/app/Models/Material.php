<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Material extends Model
{
    protected $fillable = [
        'name',
        'weight',
        'length',
        'thickness',
    ];

    public function batches()
    {
        return $this->hasMany(MaterialBatch::class);
    }
}