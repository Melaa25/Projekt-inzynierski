<?php

namespace App\Http\Requests;

use Illuminate\Foundation\Http\FormRequest;

class StoreMaterialRequest extends FormRequest
{
    public function authorize(): bool
    {
        return true;
    }

    public function rules(): array
    {
        return [
            'name' => 'required|string|max:255',
            'weight' => 'required|numeric|min:0',
            'length' => 'required|numeric|min:0',
            'thickness' => 'required|numeric|min:0',
        ];
    }
}