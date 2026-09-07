<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SupportThread;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class SupportThreadController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $threads = $request->user()->supportThreads()
            ->with('order:id,status,total_cents')
            ->withCount('messages')
            ->orderByDesc('last_message_at')
            ->get();

        return response()->json(['data' => $threads]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'order_id' => ['nullable', 'integer'],
            'issue_type' => ['required', Rule::in(SupportThread::ISSUE_TYPES)],
            'message' => ['required', 'string', 'max:2000'],
        ]);

        $orderId = $validated['order_id'] ?? null;
        if ($orderId) {
            $request->user()->orders()->findOrFail($orderId);
        }

        $thread = $request->user()->supportThreads()->create([
            'order_id' => $orderId,
            'issue_type' => $validated['issue_type'],
            'status' => 'open',
        ]);

        $label = str_replace('_', ' ', $validated['issue_type']);
        $thread->post(null, $orderId
            ? "Support request opened about order #{$orderId} — {$label}."
            : "Support request opened — {$label}.", isStaff: false, system: true);
        $thread->post($request->user(), $validated['message']);

        return response()->json(['data' => $this->withMessages($thread)], 201);
    }

    public function show(Request $request, SupportThread $thread): JsonResponse
    {
        abort_unless($thread->user_id === $request->user()->id, 404);

        return response()->json(['data' => $this->withMessages($thread)]);
    }

    public function message(Request $request, SupportThread $thread): JsonResponse
    {
        abort_unless($thread->user_id === $request->user()->id, 404);

        $validated = $request->validate(['body' => ['required', 'string', 'max:2000']]);

        if ($thread->status === 'resolved') {
            $thread->forceFill(['status' => 'open', 'resolved_at' => null])->save();
        }

        $thread->post($request->user(), $validated['body']);

        return response()->json(['data' => $this->withMessages($thread)]);
    }

    private function withMessages(SupportThread $thread): SupportThread
    {
        return $thread->fresh(['messages', 'order:id,status,total_cents']);
    }
}
