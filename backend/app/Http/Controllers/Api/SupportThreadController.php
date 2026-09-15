<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SupportThread;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Storage;
use Illuminate\Validation\Rule;
use Throwable;

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
            'message' => ['nullable', 'string', 'max:2000'],
            'image' => ['nullable', 'file', 'image', 'mimes:jpg,jpeg,png,webp,gif', 'max:4096'],
        ]);

        $message = trim($validated['message'] ?? '');
        if ($message === '' && ! $request->hasFile('image')) {
            return response()->json(['message' => 'Add a message describing the problem.'], 422);
        }

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
        $thread->post($request->user(), $message, attachmentUrl: $this->storeAttachment($request));

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

        $validated = $request->validate([
            'body' => ['nullable', 'string', 'max:2000'],
            'image' => ['nullable', 'file', 'image', 'mimes:jpg,jpeg,png,webp,gif', 'max:4096'],
        ]);

        $body = trim($validated['body'] ?? '');
        if ($body === '' && ! $request->hasFile('image')) {
            return response()->json(['message' => 'Add a message or attach a photo.'], 422);
        }

        if ($thread->status === 'resolved') {
            $thread->forceFill(['status' => 'open', 'resolved_at' => null])->save();
        }

        $thread->post($request->user(), $body, attachmentUrl: $this->storeAttachment($request));

        return response()->json(['data' => $this->withMessages($thread)]);
    }

    /**
     * Save an optional photo attached to a customer message (e.g. a damaged
     * product) under storage/app/public/support, same convention as
     * MediaController — served via /api/media/file/... so it works wherever
     * plain /storage/... doesn't.
     */
    private function storeAttachment(Request $request): ?string
    {
        if (! $request->hasFile('image')) {
            return null;
        }

        /** @var UploadedFile $file */
        $file = $request->file('image');
        $disk = Storage::disk('public');

        if (! $disk->exists('support')) {
            $disk->makeDirectory('support');
        }

        try {
            $path = $file->store('support', 'public');
        } catch (Throwable $e) {
            Log::error('Support attachment upload failed', ['error' => $e->getMessage()]);
            abort(500, 'Could not save the photo. Try again.');
        }

        if (! $path || ! $disk->exists($path)) {
            Log::error('Support attachment upload reported success but file is missing', ['path' => $path]);
            abort(500, 'The photo did not save correctly. Try again.');
        }

        return '/api/media/file/'.$path;
    }

    /**
     * The customer's 1–5 rating (and optional note) for how the conversation
     * went. One rating per thread — a repeat call edits it. Only once staff
     * have replied, so there's something to rate.
     */
    public function rate(Request $request, SupportThread $thread): JsonResponse
    {
        abort_unless($thread->user_id === $request->user()->id, 404);
        abort_unless($thread->hasStaffReply(), 422, 'There is nothing to rate yet — no reply on this conversation.');

        $validated = $request->validate([
            'rating' => ['required', 'integer', 'between:1,5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ]);

        $thread->forceFill([
            'rating' => $validated['rating'],
            'rating_comment' => $validated['comment'] ?? null,
            'rated_at' => now(),
        ])->save();

        return response()->json(['data' => $this->withMessages($thread)]);
    }

    private function withMessages(SupportThread $thread): SupportThread
    {
        // Internal admin notes (e.g. why a refund was issued) never reach the
        // customer's own view of the conversation.
        return $thread->fresh([
            'messages' => fn ($query) => $query->where('internal', false),
            'order:id,status,total_cents',
        ]);
    }
}
