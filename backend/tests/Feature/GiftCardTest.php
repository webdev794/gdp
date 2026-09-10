<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\GiftCard;
use App\Models\Order;
use App\Models\Product;
use App\Models\SupportThread;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Hash;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class GiftCardTest extends TestCase
{
    use RefreshDatabase;

    private function paidCodOrder(User $customer): Order
    {
        $order = Order::create([
            'user_id' => $customer->id,
            'status' => 'completed',
            'payment_status' => 'paid',
            'payment_method' => 'cod',
            'subtotal_cents' => 1500, 'tax_cents' => 0, 'delivery_fee_cents' => 0, 'total_cents' => 1500,
            'delivery_address' => ['name' => 'C', 'line1' => '1 St', 'city' => 'NY', 'state' => 'NY', 'postal_code' => '10001'],
        ]);
        $order->items()->create([
            'product_id' => Product::factory()->create(['category_id' => Category::factory()->create()->id])->id,
            'product_name' => 'Milk', 'sku' => 'M1', 'quantity' => 1, 'unit_price_cents' => 500, 'line_total_cents' => 500,
        ]);
        $order->items()->create([
            'product_id' => Product::factory()->create(['category_id' => Category::factory()->create()->id])->id,
            'product_name' => 'Bread', 'sku' => 'B1', 'quantity' => 1, 'unit_price_cents' => 1000, 'line_total_cents' => 1000,
        ]);

        return $order;
    }

    public function test_support_issues_a_gift_card_for_the_missing_items(): void
    {
        $customer = User::factory()->create();
        $order = $this->paidCodOrder($customer);
        $thread = SupportThread::create(['user_id' => $customer->id, 'order_id' => $order->id, 'issue_type' => 'order', 'status' => 'open']);
        $missing = $order->items->firstWhere('product_name', 'Bread');

        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));

        $res = $this->postJson("/api/admin/orders/{$order->id}/gift-card", [
            'item_ids' => [$missing->id],
            'support_thread_id' => $thread->id,
        ])->assertCreated();

        $code = $res->json('data.code');
        $pin = $res->json('data.pin');
        $this->assertSame(1000, $res->json('data.amount_cents'));

        $card = GiftCard::where('code', $code)->first();
        $this->assertNotNull($card);
        $this->assertSame($customer->id, $card->user_id);
        $this->assertSame(1000, $card->balance_cents);
        $this->assertTrue(Hash::check($pin, $card->pin_hash));

        // The code + password were posted into the support thread.
        $this->assertTrue($thread->messages()->where('body', 'like', "%{$code}%")->exists());
    }

    public function test_gift_card_cannot_exceed_what_was_paid(): void
    {
        $customer = User::factory()->create();
        $order = $this->paidCodOrder($customer); // total 1500
        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));

        $this->postJson("/api/admin/orders/{$order->id}/gift-card", ['amount_cents' => 2000])
            ->assertStatus(422);
    }

    public function test_customer_checks_their_card_and_wrong_pin_is_rejected(): void
    {
        $customer = User::factory()->create();
        $card = GiftCard::create([
            'code' => 'GC-TEST-0001', 'pin_hash' => Hash::make('secret12'),
            'user_id' => $customer->id, 'initial_cents' => 1000, 'balance_cents' => 1000, 'is_active' => true,
        ]);

        Sanctum::actingAs($customer);
        $this->postJson('/api/gift-cards/check', ['code' => 'GC-TEST-0001', 'pin' => 'secret12'])
            ->assertOk()->assertJsonPath('data.balance_cents', 1000);
        $this->postJson('/api/gift-cards/check', ['code' => 'GC-TEST-0001', 'pin' => 'wrong'])
            ->assertStatus(422);

        // Not the owner.
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/gift-cards/check', ['code' => 'GC-TEST-0001', 'pin' => 'secret12'])
            ->assertStatus(422);
    }

    public function test_checkout_applies_the_gift_card_and_keeps_the_remainder(): void
    {
        $customer = User::factory()->create(['phone' => '+1 555 0100']);
        $product = Product::factory()->create(['category_id' => Category::factory()->create()->id, 'price_cents' => 1000, 'inventory_quantity' => 10]);
        $card = GiftCard::create([
            'code' => 'GC-GIFT-0002', 'pin_hash' => Hash::make('pass1234'),
            'user_id' => $customer->id, 'initial_cents' => 5000, 'balance_cents' => 5000, 'is_active' => true,
        ]);

        Sanctum::actingAs($customer);
        $this->postJson('/api/cart/items', ['product_id' => $product->id, 'quantity' => 2]);
        $res = $this->postJson('/api/checkout', [
            'address' => ['name' => 'C', 'line1' => '1 St', 'city' => 'NY', 'state' => 'NY', 'postal_code' => '10001'],
            'gift_card_code' => 'GC-GIFT-0002', 'gift_card_pin' => 'pass1234',
        ])->assertCreated();

        $gross = $res->json('data.subtotal_cents') + $res->json('data.tax_cents')
            + $res->json('data.delivery_fee_cents') + $res->json('data.handling_fee_cents')
            + $res->json('data.small_cart_fee_cents');
        $this->assertSame($gross, $res->json('data.gift_card_discount_cents') + $res->json('data.total_cents'));
        $this->assertSame($gross, $res->json('data.gift_card_discount_cents')); // fully covered here
        $this->assertSame('paid', $res->json('data.payment_status'));
        $this->assertSame('confirmed', $res->json('data.status'));

        $card->refresh();
        $this->assertSame(5000 - $gross, $card->balance_cents);
        $this->assertDatabaseHas('gift_card_redemptions', [
            'gift_card_id' => $card->id, 'order_id' => $res->json('data.id'), 'amount_cents' => $gross,
        ]);
    }

    public function test_a_used_up_gift_card_is_rejected_at_the_next_checkout(): void
    {
        $customer = User::factory()->create(['phone' => '+1 555 0100']);
        $product = Product::factory()->create(['category_id' => Category::factory()->create()->id, 'price_cents' => 1000, 'inventory_quantity' => 10]);
        GiftCard::create([
            'code' => 'GC-ZERO-0003', 'pin_hash' => Hash::make('pass1234'),
            'user_id' => $customer->id, 'initial_cents' => 300, 'balance_cents' => 0, 'is_active' => false,
        ]);

        Sanctum::actingAs($customer);
        $this->postJson('/api/cart/items', ['product_id' => $product->id, 'quantity' => 1]);
        $this->postJson('/api/checkout', [
            'address' => ['name' => 'C', 'line1' => '1 St', 'city' => 'NY', 'state' => 'NY', 'postal_code' => '10001'],
            'gift_card_code' => 'GC-ZERO-0003', 'gift_card_pin' => 'pass1234',
        ])->assertStatus(422);
    }
}
