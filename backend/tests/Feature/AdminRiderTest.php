<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminRiderTest extends TestCase
{
    use RefreshDatabase;

    public function test_admin_grants_the_rider_role(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/admin/customers/{$user->id}", ['is_rider' => true])
            ->assertOk()
            ->assertJsonPath('data.is_rider', true);

        $this->assertTrue($user->fresh()->is_rider);
    }

    public function test_update_customer_cannot_set_is_admin(): void
    {
        $user = User::factory()->create();
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/admin/customers/{$user->id}", ['is_rider' => true, 'is_admin' => true])->assertOk();
        $this->assertFalse($user->fresh()->is_admin);
    }

    public function test_a_normal_user_cannot_grant_the_rider_role(): void
    {
        Sanctum::actingAs(User::factory()->create());

        $this->patchJson('/api/admin/customers/1', ['is_rider' => true])->assertForbidden();
    }

    public function test_riders_endpoint_lists_only_riders(): void
    {
        $rider = User::factory()->create(['is_rider' => true, 'name' => 'Alex Rider']);
        User::factory()->create();
        Sanctum::actingAs($this->admin());

        $this->getJson('/api/admin/riders')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.id', $rider->id);
    }

    public function test_admin_assigns_a_rider_to_an_order(): void
    {
        $rider = User::factory()->create(['is_rider' => true, 'name' => 'Alex Rider']);
        $order = $this->order();
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/admin/orders/{$order->id}", ['delivery_partner_id' => $rider->id])
            ->assertOk()
            ->assertJsonPath('data.delivery_partner_id', $rider->id)
            ->assertJsonPath('data.courier_name', 'Alex Rider');
    }

    public function test_assigning_a_non_rider_is_rejected(): void
    {
        $notRider = User::factory()->create();
        $order = $this->order();
        Sanctum::actingAs($this->admin());

        $this->patchJson("/api/admin/orders/{$order->id}", ['delivery_partner_id' => $notRider->id])
            ->assertStatus(422);
    }

    private function admin(): User
    {
        return User::factory()->create(['is_admin' => true]);
    }

    private function order(): Order
    {
        return Order::create([
            'user_id' => User::factory()->create()->id, 'status' => 'ready_for_delivery', 'payment_status' => 'paid',
            'subtotal_cents' => 1000, 'tax_cents' => 0, 'delivery_fee_cents' => 0, 'total_cents' => 1000,
            'delivery_address' => ['name' => 'X', 'line1' => '1 St', 'city' => 'NY', 'state' => 'NY', 'postal_code' => '10001'],
        ]);
    }
}
