<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class ProfileController extends Controller
{
    /**
     * Update the signed-in customer's own name / phone number. Phone is optional
     * at sign-up; this is where a customer can add it before checkout (or the
     * checkout call saves it for them).
     */
    public function update(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'phone' => ['sometimes', 'nullable', 'string', 'max:32'],
        ]);

        if (array_key_exists('phone', $validated)) {
            $validated['phone'] = $validated['phone'] === null ? null : trim($validated['phone']);
        }

        $request->user()->update($validated);

        return response()->json(['data' => $request->user()->fresh()]);
    }
}
