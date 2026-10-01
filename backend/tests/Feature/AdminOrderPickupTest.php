<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminOrderPickupTest extends TestCase
{
    use RefreshDatabase;

    private function order(string $status): Order
    {
        return Order::create([
            'user_id' => User::factory()->create()->id,
            'status' => $status, 'payment_status' => 'paid', 'payment_method' => 'card',
            'subtotal_cents' => 100, 'tax_cents' => 0, 'delivery_fee_cents' => 0, 'total_cents' => 100,
            'delivery_address' => ['name' => 'C', 'line1' => '1', 'city' => 'Kakata', 'state' => 'Margibi', 'postal_code' => ''],
        ]);
    }

    public function test_admin_can_close_an_open_order_as_picked_up_without_a_courier(): void
    {
        $order = $this->order('packing');
        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));

        $this->patchJson("/api/admin/orders/{$order->id}", ['picked_up' => true])
            ->assertOk()
            ->assertJsonPath('data.status', 'completed')
            ->assertJsonPath('data.courier_name', 'Customer pickup');

        $this->assertNotNull($order->fresh()->delivered_at);
        $this->assertNull($order->fresh()->delivery_partner_id);
    }

    public function test_closed_orders_cannot_be_marked_picked_up(): void
    {
        $order = $this->order('cancelled');
        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));

        $this->patchJson("/api/admin/orders/{$order->id}", ['picked_up' => true])->assertUnprocessable();
        $this->assertSame('cancelled', $order->fresh()->status);
    }

    public function test_admin_cancel_needs_a_reason_shown_to_the_customer(): void
    {
        $order = $this->order('confirmed');
        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));

        $this->patchJson("/api/admin/orders/{$order->id}", ['status' => 'cancelled'])->assertUnprocessable();
        $this->assertSame('confirmed', $order->fresh()->status);

        $this->patchJson("/api/admin/orders/{$order->id}", ['status' => 'cancelled', 'cancel_reason' => 'Store closed / holiday'])->assertOk();
        $this->assertSame('Store closed / holiday', $order->fresh()->cancel_reason);
        $this->assertSame('admin', $order->fresh()->cancelled_by);

        Sanctum::actingAs($order->user);
        $this->getJson('/api/orders')->assertJsonPath('data.0.cancel_reason', 'Store closed / holiday');
    }

    public function test_open_order_counts_for_the_top_bar(): void
    {
        $this->order('confirmed');
        $this->order('confirmed');
        $this->order('out_for_delivery');
        $this->order('completed');
        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));

        $this->getJson('/api/admin/orders/open-counts')
            ->assertOk()
            ->assertJsonPath('data.total', 3)
            ->assertJsonPath('data.by_status.confirmed', 2)
            ->assertJsonPath('data.by_status.out_for_delivery', 1);
    }
}
