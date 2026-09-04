<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class DeliveryWorkflowTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_can_advance_an_order_through_every_delivery_state(): void
    {
        $order = $this->paidOrder();
        Sanctum::actingAs($this->admin());

        foreach (['preparing', 'out_for_delivery', 'completed'] as $status) {
            $this->patchJson("/api/admin/orders/{$order->id}", ['status' => $status])
                ->assertOk()
                ->assertJsonPath('data.status', $status);
        }
    }

    public function test_delivery_steps_cannot_be_skipped(): void
    {
        $order = $this->paidOrder();
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/admin/orders/{$order->id}", ['status' => 'completed'])
            ->assertUnprocessable();

        $this->assertDatabaseHas('orders', ['id' => $order->id, 'status' => 'confirmed']);
    }

    public function test_an_unpaid_order_cannot_be_advanced(): void
    {
        $order = $this->paidOrder(['status' => 'pending_payment', 'payment_status' => 'pending']);
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/admin/orders/{$order->id}", ['status' => 'preparing'])
            ->assertUnprocessable();
    }

    public function test_a_completed_order_is_terminal(): void
    {
        $order = $this->paidOrder(['status' => 'completed']);
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/admin/orders/{$order->id}", ['status' => 'preparing'])
            ->assertUnprocessable();
    }

    public function test_admin_can_cancel_a_preparing_order(): void
    {
        $order = $this->paidOrder(['status' => 'preparing']);
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/admin/orders/{$order->id}", ['status' => 'cancelled'])
            ->assertOk()
            ->assertJsonPath('data.status', 'cancelled');
    }

    public function test_admin_can_assign_a_courier_without_changing_status(): void
    {
        $order = $this->paidOrder(['status' => 'preparing']);
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/admin/orders/{$order->id}", ['courier_name' => 'Sam Rider'])
            ->assertOk()
            ->assertJsonPath('data.courier_name', 'Sam Rider')
            ->assertJsonPath('data.status', 'preparing');
    }

    public function test_patch_requires_a_status_or_courier_field(): void
    {
        $order = $this->paidOrder();
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/admin/orders/{$order->id}", [])->assertUnprocessable();
    }

    public function test_unknown_status_value_is_rejected(): void
    {
        $order = $this->paidOrder();
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/admin/orders/{$order->id}", ['status' => 'shipped'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['status']);
    }

    public function test_non_admin_cannot_reach_admin_endpoints(): void
    {
        $order = $this->paidOrder();
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/admin/orders')->assertForbidden();
        $this->patchJson("/api/admin/orders/{$order->id}", ['status' => 'preparing'])->assertForbidden();
    }

    public function test_guest_cannot_reach_admin_endpoints(): void
    {
        $this->getJson('/api/admin/orders')->assertUnauthorized();
    }

    public function test_admin_order_list_spans_every_customer(): void
    {
        $this->paidOrder();
        $this->paidOrder();
        Sanctum::actingAs($this->admin());

        $this->getJson('/api/admin/orders')
            ->assertOk()
            ->assertJsonPath('meta.total', 2)
            ->assertJsonPath('data.0.user.email', fn ($email) => is_string($email));
    }

    public function test_admin_can_filter_orders_by_status(): void
    {
        $this->paidOrder(['status' => 'preparing']);
        $this->paidOrder(['status' => 'confirmed']);
        Sanctum::actingAs($this->admin());

        $this->getJson('/api/admin/orders?status=preparing')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.status', 'preparing');
    }

    private function admin(): User
    {
        return User::factory()->create(['is_admin' => true]);
    }

    private function paidOrder(array $overrides = []): Order
    {
        return Order::create([
            'user_id' => User::factory()->create()->id,
            'status' => 'confirmed',
            'payment_status' => 'paid',
            'subtotal_cents' => 1000,
            'tax_cents' => 89,
            'delivery_fee_cents' => 599,
            'total_cents' => 1688,
            'delivery_address' => [
                'name' => 'Test Customer', 'line1' => '10 Main Street',
                'city' => 'Brooklyn', 'state' => 'NY', 'postal_code' => '11201',
            ],
            ...$overrides,
        ]);
    }
}
