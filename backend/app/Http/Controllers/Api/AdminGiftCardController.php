<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GiftCard;
use App\Models\Order;
use App\Models\SupportThread;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;

class AdminGiftCardController extends Controller
{
    /**
     * Issue store credit against a paid order — e.g. items confirmed missing on a
     * cash delivery. The card is bound to the order's customer; the code + a
     * one-time password are returned and posted into the support thread.
     */
    public function issue(Request $request, Order $order): JsonResponse
    {
        $data = $request->validate([
            'item_ids' => ['sometimes', 'array'],
            'item_ids.*' => ['integer'],
            'amount_cents' => ['sometimes', 'integer', 'min:1'],
            'support_thread_id' => ['sometimes', 'nullable', 'integer', 'exists:support_threads,id'],
            'reason' => ['sometimes', 'nullable', 'string', 'max:200'],
        ]);

        if (! in_array($order->payment_status, ['paid', 'partially_refunded'], true)) {
            return response()->json(['message' => 'Store credit can only be issued against a paid order.'], 422);
        }

        $items = ! empty($data['item_ids'])
            ? $order->items()->whereIn('id', $data['item_ids'])->get()
            : collect();

        $amount = $items->isNotEmpty()
            ? (int) $items->sum('line_total_cents')
            : (int) ($data['amount_cents'] ?? 0);

        $returned = (int) $order->refunded_amount_cents + $order->giftCardRefundedCents();
        $room = max(0, (int) $order->total_cents - $returned);

        if ($amount < 1 || $amount > $room) {
            return response()->json([
                'message' => 'Amount must be between $0.01 and $'.number_format($room / 100, 2)
                    .' (already returned $'.number_format($returned / 100, 2).').',
            ], 422);
        }

        $pin = GiftCard::makePin();
        $card = GiftCard::create([
            'code' => GiftCard::makeCode(),
            'pin_hash' => Hash::make($pin),
            'user_id' => $order->user_id,
            'issued_by' => $request->user()->id,
            'support_thread_id' => $data['support_thread_id'] ?? null,
            'order_id' => $order->id,
            'initial_cents' => $amount,
            'balance_cents' => $amount,
            'is_active' => true,
            'reason' => $data['reason'] ?? ($items->isNotEmpty()
                ? 'Missing: '.$items->pluck('product_name')->implode(', ')
                : null),
        ]);

        if (! empty($data['support_thread_id'])) {
            $money = '$'.number_format($amount / 100, 2);
            $what = $items->isNotEmpty()
                ? ' for the missing item(s): '.$items->pluck('product_name')->implode(', ')
                : '';
            SupportThread::find($data['support_thread_id'])?->post(
                null,
                "Store credit {$money} issued{$what}.\nGift card: {$card->code}\nPassword: {$pin}\n"
                    .'Enter both at checkout on your next order to use the balance.',
                isStaff: true,
                system: true,
            );
        }

        return response()->json(['data' => [
            'code' => $card->code,
            'pin' => $pin,
            'amount_cents' => $amount,
            'order_id' => $order->id,
        ]], 201);
    }
}
