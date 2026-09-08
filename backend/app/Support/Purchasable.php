<?php

namespace App\Support;

use App\Models\Product;
use App\Models\ProductVariant;

/**
 * Resolves the effective price / stock / availability for a line item: the
 * chosen variant when there is one, otherwise the product itself.
 */
class Purchasable
{
    /**
     * @return array{price_cents: int, compare_at_price_cents: int|null, inventory_quantity: int, active: bool, label: string|null}
     */
    public static function resolve(Product $product, ?ProductVariant $variant): array
    {
        $categoryActive = (bool) $product->category?->is_active;

        if ($variant) {
            return [
                'price_cents' => (int) $variant->price_cents,
                'compare_at_price_cents' => $variant->compare_at_price_cents !== null ? (int) $variant->compare_at_price_cents : null,
                'inventory_quantity' => (int) $variant->inventory_quantity,
                'active' => $product->is_active && $categoryActive && $variant->is_active,
                'label' => $variant->label,
            ];
        }

        return [
            'price_cents' => (int) $product->price_cents,
            'compare_at_price_cents' => $product->compare_at_price_cents !== null ? (int) $product->compare_at_price_cents : null,
            'inventory_quantity' => (int) $product->inventory_quantity,
            'active' => $product->is_active && $categoryActive,
            'label' => null,
        ];
    }
}
