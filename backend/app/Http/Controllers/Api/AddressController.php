<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Address;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class AddressController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        return response()->json(['data' => $request->user()->addresses()->latest()->get()]);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $request->validate($this->rules());
        $address = DB::transaction(function () use ($request, $data): Address {
            if ($data['is_default'] ?? false) $request->user()->addresses()->update(['is_default' => false]);
            return $request->user()->addresses()->create($data);
        });
        return response()->json(['data' => $address], 201);
    }

    private function rules(): array
    {
        return ['label' => ['sometimes', 'string', 'max:40'], 'name' => ['required', 'string', 'max:120'], 'line1' => ['required', 'string', 'max:255'], 'line2' => ['nullable', 'string', 'max:255'], 'city' => ['required', 'string', 'max:100'], 'state' => ['required', 'string', 'max:60'], 'postal_code' => ['required', 'string', 'max:12'], 'latitude' => ['sometimes', 'nullable', 'numeric', 'between:-90,90'], 'longitude' => ['sometimes', 'nullable', 'numeric', 'between:-180,180'], 'is_default' => ['sometimes', 'boolean']];
    }
}