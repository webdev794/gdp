<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminDashboardTest extends TestCase
{
    use RefreshDatabase;

    public function test_metrics_summarise_orders_and_paid_revenue(): void
    {
        $this->order('confirmed', 'paid', 2000);
        $this->order('packing', 'paid', 3000);
        $this->order('pending_payment', 'pending', 1500);

        Sanctum::actingAs($this->admin());

        $this->getJson('/api/admin/metrics')
            ->assertOk()
            ->assertJsonPath('data.orders_total', 3)
            ->assertJsonPath('data.awaiting_fulfilment', 2)
            ->assertJsonPath('data.revenue_cents', 5000)
            ->assertJsonPath('data.orders_by_status.confirmed', 1);
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

    private function order(string $status, string $paymentStatus, int $total, ?User $user = null): Order
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
        ]);
    }
}
