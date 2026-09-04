<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class Order extends Model
{
    use HasFactory;

    /**
     * Delivery states an administrator may move a paid order through, and the
     * states each one may advance to. Steps cannot be skipped, and completed or
     * cancelled orders are terminal.
     */
    public const DELIVERY_TRANSITIONS = [
        'confirmed' => ['preparing', 'cancelled'],
        'preparing' => ['out_for_delivery', 'cancelled'],
        'out_for_delivery' => ['completed'],
        'completed' => [],
        'cancelled' => [],
    ];

    protected $fillable = [
        'user_id', 'status', 'courier_name', 'payment_status', 'subtotal_cents', 'tax_cents',
        'delivery_fee_cents', 'total_cents', 'delivery_address',
        'stripe_payment_intent_id',
    ];

    protected function casts(): array
    {
        return [
            'subtotal_cents' => 'integer',
            'tax_cents' => 'integer',
            'delivery_fee_cents' => 'integer',
            'total_cents' => 'integer',
            'delivery_address' => 'array',
        ];
    }

    public function user(): BelongsTo { return $this->belongsTo(User::class); }
    public function items(): HasMany { return $this->hasMany(OrderItem::class); }

    public function canTransitionTo(string $status): bool
    {
        return $this->payment_status === 'paid'
            && in_array($status, self::DELIVERY_TRANSITIONS[$this->status] ?? [], true);
    }
}