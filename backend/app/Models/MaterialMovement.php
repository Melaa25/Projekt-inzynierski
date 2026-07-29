<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class MaterialMovement extends Model
{
    protected $fillable = [
        'material_batch_id',
        'user_id',
        'type',
        'quantity_delta',
        'destination',
        'note',
        'previous_status',
        'new_status',
        'previous_location_id',
        'new_location_id',
    ];

    public function batch()
    {
        return $this->belongsTo(MaterialBatch::class, 'material_batch_id');
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