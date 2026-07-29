<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Str;

class MaterialBatch extends Model
{
    public const TYPE_MATERIAL = 'material';
    public const TYPE_WASTE = 'waste';

    public const STATUS_IN_STOCK = 'in_stock';
    public const STATUS_IN_PRODUCTION = 'in_production';
    public const STATUS_RESERVED = 'reserved';
    public const STATUS_MISSING = 'missing';
    public const STATUS_DAMAGED = 'damaged';

    public const ALLOWED_STATUSES = [
        self::STATUS_IN_STOCK,
        self::STATUS_IN_PRODUCTION,
        self::STATUS_RESERVED,
        self::STATUS_MISSING,
        self::STATUS_DAMAGED,
    ];

    protected $fillable = [
        'type',
        'material_id',
        'batch_code',
        'quantity',
        'total_weight',
        'current_location_id',
        'status',
    ];

    protected static function booted(): void
    {
        static::creating(function (MaterialBatch $batch): void {
            if (empty($batch->batch_code)) {
                $batch->batch_code = static::generateBatchCode($batch);
            }
        });
    }

    public function material()
    {
        return $this->belongsTo(Material::class);
    }

    public function currentLocation()
    {
        return $this->belongsTo(WarehouseLocation::class, 'current_location_id');
    }

    public function movements()
    {
        return $this->hasMany(MaterialMovement::class);
    }

    public static function findActiveForReceiving(?int $materialId, string $type, ?int $locationId): ?self
    {
        return static::query()
            ->where('type', $type)
            ->where('material_id', $materialId)
            ->where('current_location_id', $locationId)
            ->where('status', self::STATUS_IN_STOCK)
            ->first();
    }

    private static function generateBatchCode(MaterialBatch $batch): string
    {
        $prefix = $batch->type === self::TYPE_WASTE
            ? 'ODP'
            : static::buildMaterialPrefix($batch->material?->name ?? '');

        $lastCodeForPrefix = static::query()
            ->where('batch_code', 'like', $prefix.'-%')
            ->orderByDesc('batch_code')
            ->value('batch_code');

        $nextNumber = 1;
        if (is_string($lastCodeForPrefix) && preg_match('/^(?:[A-Z]{2,3})-(\d+)$/', $lastCodeForPrefix, $matches) === 1) {
            $nextNumber = ((int) $matches[1]) + 1;
        }

        return sprintf('%s-%04d', $prefix, $nextNumber);
    }

    private static function buildMaterialPrefix(string $name): string
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