<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Material extends Model
{
    protected $fillable = [
        'name',
        'serial_number',
        'weight',
        'length',
        'location',
    ];
}
