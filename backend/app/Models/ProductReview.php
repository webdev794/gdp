<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ProductReview extends Model
{
    protected $fillable = ['order_id', 'product_id', 'user_id', 'rating', 'comment', 'is_hidden', 'approved_at'];

    protected function casts(): array
    {
        return ['rating' => 'integer', 'is_hidden' => 'boolean', 'approved_at' => 'datetime'];
    }

    /** Shown on the store: approved by admin and not hidden. */
    public function scopeVisible($query)
    {
        return $query->where('is_hidden', false)->whereNotNull('approved_at');
    }

    public function product(): BelongsTo
    {
        return $this->belongsTo(Product::class);
    }

    public function customer(): BelongsTo
    {
        return $this->belongsTo(User::class, 'user_id');
    }

    /** Public-facing shape: first name + last initial, never the email. */
    public function toPublicArray(): array
    {
        $parts = preg_split('/\s+/', trim((string) $this->customer?->name)) ?: [];
        $first = $parts[0] ?? '';
        $last = count($parts) > 1 ? mb_substr(end($parts), 0, 1).'.' : '';

        return [
            'id' => $this->id,
            'order_id' => $this->order_id,
            'product_id' => $this->product_id,
            'rating' => $this->rating,
            'comment' => $this->comment,
            'author' => trim("$first $last") ?: 'Customer',
            'created_at' => $this->created_at?->toISOString(),
            'updated_at' => $this->updated_at?->toISOString(),
        ];
    }
}
