<?php

namespace App\Http\Requests;

use App\Models\MaterialBatch;
use Illuminate\Foundation\Http\FormRequest;
use Illuminate\Validation\Rule;

class UpdateMaterialBatchStatusRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'status' => ['required', Rule::in(MaterialBatch::ALLOWED_STATUSES)],
            'note' => ['nullable', 'string'],
        ];
    }
}