<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\ProductReview;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class ProductReviewTest extends TestCase
{
    use RefreshDatabase;

    private function product(): Product
    {
        $category = Category::create(['name' => 'Fruit', 'slug' => 'fruit']);

        return Product::create([
            'category_id' => $category->id, 'name' => 'Gala Apples', 'slug' => 'gala-apples', 'sku' => 'APL-1',
            'price_cents' => 449, 'inventory_quantity' => 10, 'is_active' => true,
        ]);
    }

    private function deliver(User $customer, Product $product, string $status = 'completed'): Order
    {
        $order = Order::create([
            'user_id' => $customer->id,
            'status' => $status, 'payment_status' => 'paid', 'payment_method' => 'card',
            'subtotal_cents' => 449, 'tax_cents' => 0, 'delivery_fee_cents' => 0, 'total_cents' => 449,
            'delivery_address' => ['name' => 'C', 'line1' => '1 St', 'city' => 'Kakata', 'state' => 'Margibi', 'postal_code' => ''],
        ]);
        $order->items()->create([
            'product_id' => $product->id, 'product_name' => $product->name, 'sku' => $product->sku,
            'quantity' => 1, 'unit_price_cents' => 449, 'line_total_cents' => 449,
        ]);

        return $order;
    }

    public function test_a_customer_reviews_an_ordered_item_once_per_order(): void
    {
        $product = $this->product();
        $customer = User::factory()->create(['name' => 'Jane Doe']);
        $first = $this->deliver($customer, $product, 'confirmed');
        $second = $this->deliver($customer, $product, 'completed');
        Sanctum::actingAs($customer);

        $this->postJson("/api/orders/{$first->id}/reviews", ['product_id' => $product->id, 'rating' => 4, 'comment' => 'Crisp'])
            ->assertCreated()
            ->assertJsonPath('data.author', 'Jane D.');

        // Same order again is refused; a different order can be reviewed.
        $this->postJson("/api/orders/{$first->id}/reviews", ['product_id' => $product->id, 'rating' => 1])->assertUnprocessable();
        $this->postJson("/api/orders/{$second->id}/reviews", ['product_id' => $product->id, 'rating' => 2])->assertCreated();

        // New reviews wait for admin approval before they are shown.
        $this->assertSame(0, $product->fresh()->rating_count);
        $this->getJson('/api/products/gala-apples/reviews')->assertJsonPath('summary.count', 0);

        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));
        $this->getJson('/api/admin/notifications')->assertJsonPath('data.pending_reviews', 2);
        $this->getJson('/api/admin/reviews?status=pending')->assertJsonPath('meta.total', 2);
        foreach (ProductReview::pluck('id') as $id) {
            $this->patchJson("/api/admin/reviews/{$id}", ['approved' => true])->assertOk();
        }
        Sanctum::actingAs($customer);

        $this->assertSame(3.0, $product->fresh()->rating_avg);
        $this->assertSame(2, $product->fresh()->rating_count);

        $this->getJson('/api/products/gala-apples/reviews')
            ->assertOk()
            ->assertJsonPath('summary.count', 2)
            ->assertJsonMissingPath('data.0.email');

        $this->getJson("/api/orders/{$first->id}")->assertJsonPath('data.product_reviews.0.rating', 4);
    }

    public function test_unpaid_cancelled_or_other_orders_cannot_review(): void
    {
        $product = $this->product();
        $customer = User::factory()->create();
        $unpaid = $this->deliver($customer, $product, 'pending_payment');
        $cancelled = $this->deliver($customer, $product, 'cancelled');
        $someoneElse = $this->deliver(User::factory()->create(), $product);
        Sanctum::actingAs($customer);

        $this->postJson("/api/orders/{$unpaid->id}/reviews", ['product_id' => $product->id, 'rating' => 5])->assertUnprocessable();
        $this->postJson("/api/orders/{$cancelled->id}/reviews", ['product_id' => $product->id, 'rating' => 5])->assertUnprocessable();
        $this->postJson("/api/orders/{$someoneElse->id}/reviews", ['product_id' => $product->id, 'rating' => 5])->assertNotFound();
        $this->assertSame(0, ProductReview::count());
    }

    public function test_admin_can_hide_and_delete_reviews(): void
    {
        $product = $this->product();
        $a = User::factory()->create();
        $b = User::factory()->create();
        $ra = ProductReview::create(['order_id' => $this->deliver($a, $product)->id, 'product_id' => $product->id, 'user_id' => $a->id, 'rating' => 1, 'approved_at' => now()]);
        ProductReview::create(['order_id' => $this->deliver($b, $product)->id, 'product_id' => $product->id, 'user_id' => $b->id, 'rating' => 5, 'approved_at' => now()]);
        $product->refreshRating();

        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));

        $this->getJson('/api/admin/reviews')->assertOk()->assertJsonPath('meta.total', 2);
        $this->patchJson("/api/admin/reviews/{$ra->id}", ['is_hidden' => true])->assertOk();

        $this->assertSame(5.0, $product->fresh()->rating_avg);
        $this->getJson('/api/products/gala-apples/reviews')->assertJsonPath('summary.count', 1);

        $this->deleteJson("/api/admin/reviews/{$ra->id}")->assertOk();
        $this->assertSame(1, ProductReview::count());
    }

    public function test_customers_cannot_moderate_reviews(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/admin/reviews')->assertForbidden();
    }
}
