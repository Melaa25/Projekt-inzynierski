<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MaterialMovement extends Model
{
    protected $fillable = [
        'material_id',
        'user_id',
        'type',
        'destination',
        'note',
        'previous_status',
        'new_status',
        'previous_location_id',
        'new_location_id',
    ];

    public function material()
    {
        return $this->belongsTo(Material::class);
    }

    public function user()
    {
        return $this->belongsTo(User::class);
    }

    public function previousLocation()
    {
        return $this->belongsTo(WarehouseLocation::class, 'previous_location_id');
    }

    public function newLocation()
    {
        return $this->belongsTo(WarehouseLocation::class, 'new_location_id');
    }
}
