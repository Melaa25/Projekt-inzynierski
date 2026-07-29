<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class ReceiveWasteBatchRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'quantity' => ['required', 'integer', 'min:1'],
            'weight' => ['nullable', 'numeric', 'min:0'],
            'location_id' => ['required', 'integer', 'exists:warehouse_locations,id'],
            'target_batch_id' => ['nullable', 'integer', 'exists:material_batches,id'],
            'note' => ['nullable', 'string'],
        ];
    }
}
