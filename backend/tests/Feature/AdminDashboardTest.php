<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminDashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_metrics_summarise_orders_and_paid_revenue(): void
    {
        $discounted = $this->order('confirmed', 'paid', 2000);
        $this->line($discounted, quantity: 2, unit: 800, regular: 1000); // $4.00 discount
        $this->order('packing', 'paid', 3000, attributes: ['payment_method' => 'cod']);
        $this->order('pending_payment', 'pending', 1500);

        Sanctum::actingAs($this->admin());

        $this->getJson('/api/admin/metrics')
            ->assertOk()
            ->assertJsonPath('data.orders_total', 3)
            ->assertJsonPath('data.awaiting_fulfilment', 2)
            ->assertJsonPath('data.revenue_cents', 5000)
            ->assertJsonPath('data.avg_order_cents', 2500) // 5000 paid / 2 paid orders
            ->assertJsonPath('data.discount_cents', 400)
            ->assertJsonPath('data.cod_orders', 1)
            ->assertJsonPath('data.refunded_cents', 0)
            ->assertJsonPath('data.orders_by_status.confirmed', 1);
    }

    public function test_insights_return_a_weekday_hour_activity_grid(): void
    {
        Carbon::setTestNow('2026-09-15 14:00:00');

        $this->order('confirmed', 'paid', 2000);
        $this->order('packing', 'paid', 3000);

        Sanctum::actingAs($this->admin());

        $this->getJson('/api/admin/metrics/insights')
            ->assertOk()
            ->assertJsonCount(7, 'data.activity.matrix')
            ->assertJsonCount(24, 'data.activity.matrix.0')
            ->assertJsonPath('data.activity.rows.0', 'Mon')
            ->assertJsonPath('data.activity.peak', 2); // both orders land on Mon 14:00

        Carbon::setTestNow();
    }

    public function test_non_admin_cannot_view_insights(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/admin/metrics/insights')->assertForbidden();
    }

    public function test_customer_list_excludes_admins_and_totals_paid_spend(): void
    {
        $this->admin();
        $spender = User::factory()->create();
        User::factory()->create(); // a second plain customer
        $this->order('confirmed', 'paid', 2500, $spender);
        $this->order('pending_payment', 'pending', 900, $spender);

        Sanctum::actingAs($this->admin());

        $response = $this->getJson('/api/admin/customers')->assertOk();
        $response->assertJsonPath('meta.total', 2); // two plain customers; both admins excluded
        $row = collect($response->json('data'))->firstWhere('id', $spender->id);
        $this->assertSame(2, $row['orders_count']);
        $this->assertSame(2500, $row['spent_cents']);
    }

    public function test_non_admin_cannot_view_metrics(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->getJson('/api/admin/metrics')->assertForbidden();
    }

    public function test_customer_detail_returns_that_customers_orders(): void
    {
        $customer = User::factory()->create();
        $this->order('confirmed', 'paid', 2500, $customer);
        $this->order('pending_payment', 'pending', 900, User::factory()->create());

        Sanctum::actingAs($this->admin());

        $this->getJson("/api/admin/customers/{$customer->id}")
            ->assertOk()
            ->assertJsonPath('data.email', $customer->email)
            ->assertJsonCount(1, 'data.orders');
    }

    public function test_customer_detail_hides_admin_accounts(): void
    {
        $otherAdmin = $this->admin();
        Sanctum::actingAs($this->admin());

        $this->getJson("/api/admin/customers/{$otherAdmin->id}")->assertNotFound();
    }

    private function admin(): User
    {
        return User::factory()->create(['is_admin' => true]);
    }

    private function order(string $status, string $paymentStatus, int $total, ?User $user = null, array $attributes = []): Order
    {
        return Order::create([
            'user_id' => ($user ?? User::factory()->create())->id,
            'status' => $status,
            'payment_status' => $paymentStatus,
            'subtotal_cents' => $total,
            'tax_cents' => 0,
            'delivery_fee_cents' => 0,
            'total_cents' => $total,
            'delivery_address' => [
                'name' => 'Test Customer', 'line1' => '10 Main Street',
                'city' => 'Brooklyn', 'state' => 'NY', 'postal_code' => '11201',
            ],
            ...$attributes,
        ]);
    }

    private function line(Order $order, int $quantity, int $unit, ?int $regular = null): void
    {
        $order->items()->create([
            'product_id' => Product::factory()->create(['category_id' => Category::factory()->create()->id])->id,
            'product_name' => 'Line item',
            'sku' => 'GDP-TEST-'.$order->items()->count(),
            'quantity' => $quantity,
            'unit_price_cents' => $unit,
            'compare_at_price_cents' => $regular,
            'line_total_cents' => $unit * $quantity,
        ]);
    }
}
