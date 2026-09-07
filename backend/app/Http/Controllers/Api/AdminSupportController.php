<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SupportThread;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class AdminSupportController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'status' => ['sometimes', Rule::in(['open', 'resolved'])],
            'issue_type' => ['sometimes', Rule::in(SupportThread::ISSUE_TYPES)],
        ]);

        $threads = SupportThread::query()
            ->with(['user:id,name,email', 'order:id,status,total_cents'])
            ->withCount('messages')
            ->when($validated['status'] ?? null, fn ($q, $s) => $q->where('status', $s))
            ->when($validated['issue_type'] ?? null, fn ($q, $t) => $q->where('issue_type', $t))
            ->orderByRaw("status = 'open' desc")
            ->orderByDesc('last_message_at')
            ->paginate(30);

        return response()->json([
            'data' => $threads->items(),
            'meta' => [
                'current_page' => $threads->currentPage(),
                'last_page' => $threads->lastPage(),
                'total' => $threads->total(),
                'open' => SupportThread::where('status', 'open')->count(),
            ],
        ]);
    }

    public function show(SupportThread $thread): JsonResponse
    {
        $thread->load(['messages', 'user:id,name,email', 'order.items', 'order.refunds']);

        return response()->json(['data' => $thread]);
    }

    public function message(Request $request, SupportThread $thread): JsonResponse
    {
        $validated = $request->validate(['body' => ['required', 'string', 'max:2000']]);

        $thread->post($request->user(), $validated['body'], isStaff: true);

        return response()->json(['data' => $thread->fresh(['messages', 'user:id,name,email', 'order.items', 'order.refunds'])]);
    }

    public function update(Request $request, SupportThread $thread): JsonResponse
    {
        $validated = $request->validate(['status' => ['required', Rule::in(['open', 'resolved'])]]);

        $thread->forceFill([
            'status' => $validated['status'],
            'resolved_at' => $validated['status'] === 'resolved' ? now() : null,
        ])->save();

        return response()->json(['data' => $thread->fresh(['messages', 'user:id,name,email', 'order.items', 'order.refunds'])]);
    }
}
