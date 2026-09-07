<?php

namespace Tests\Feature;

use App\Models\Order;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Carbon;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminMetricsTimeseriesTest extends TestCase
{
    use RefreshDatabase;

    private function order(array $attributes = []): Order
    {
        $createdAt = $attributes['created_at'] ?? null;
        unset($attributes['created_at']);

        $order = Order::create([
            'user_id' => User::factory()->create()->id,
            'status' => 'confirmed',
            'payment_status' => 'paid',
            'payment_method' => 'card',
            'subtotal_cents' => 1000,
            'tax_cents' => 0,
            'delivery_fee_cents' => 0,
            'total_cents' => 1000,
            'delivery_address' => ['name' => 'x', 'line1' => 'y'],
            ...$attributes,
        ]);

        if ($createdAt !== null) {
            $order->forceFill(['created_at' => $createdAt])->saveQuietly();
        }

        return $order;
    }

    public function test_daily_buckets_are_gap_filled_and_dated(): void
    {
        Carbon::setTestNow('2026-09-07 12:00:00');
        $admin = User::factory()->create();
        $admin->forceFill(['is_admin' => true])->save();
        Sanctum::actingAs($admin);

        $this->order(['created_at' => '2026-09-07 09:00:00']);
        $this->order(['created_at' => '2026-09-07 20:00:00']);
        $this->order(['created_at' => '2026-09-05 10:00:00', 'payment_status' => 'pending', 'total_cents' => 500]);

        $data = $this->getJson('/api/admin/metrics/timeseries?bucket=day')
            ->assertOk()
            ->assertJsonPath('data.bucket', 'day')
            ->assertJsonPath('data.totals.orders', 3)
            ->assertJsonPath('data.totals.paid_orders', 2)
            ->assertJsonPath('data.totals.revenue_cents', 2000)
            ->json('data.series');

        $this->assertCount(14, $data); // 13-day default span, inclusive
        $today = collect($data)->firstWhere('period', '2026-09-07');
        $this->assertSame(2, $today['orders']);
        $gap = collect($data)->firstWhere('period', '2026-09-06');
        $this->assertSame(0, $gap['orders']);

        Carbon::setTestNow();
    }

    public function test_month_buckets_and_status_breakdown_respect_the_window(): void
    {
        Carbon::setTestNow('2026-09-15 12:00:00');
        $admin = User::factory()->create();
        $admin->forceFill(['is_admin' => true])->save();
        Sanctum::actingAs($admin);

        $this->order(['created_at' => '2026-09-10 10:00:00', 'status' => 'completed']);
        $this->order(['created_at' => '2026-08-02 10:00:00', 'status' => 'cancelled', 'payment_method' => 'cod']);
        $this->order(['created_at' => '2023-01-01 10:00:00']); // outside the 11-month window

        $response = $this->getJson('/api/admin/metrics/timeseries?bucket=month')->assertOk();

        $response->assertJsonPath('data.totals.orders', 2)
            ->assertJsonPath('data.by_status.completed', 1)
            ->assertJsonPath('data.by_status.cancelled', 1)
            ->assertJsonPath('data.by_payment_method.cod', 1)
            ->assertJsonPath('data.by_payment_method.card', 1);

        $series = $response->json('data.series');
        $this->assertCount(12, $series);
        $this->assertSame('2026-09-01', end($series)['period']);

        Carbon::setTestNow();
    }

    public function test_a_custom_range_is_honoured(): void
    {
        $admin = User::factory()->create();
        $admin->forceFill(['is_admin' => true])->save();
        Sanctum::actingAs($admin);

        $this->order(['created_at' => '2026-03-15 10:00:00']);

        $this->getJson('/api/admin/metrics/timeseries?bucket=day&from=2026-03-14&to=2026-03-16')
            ->assertOk()
            ->assertJsonPath('data.from', '2026-03-14')
            ->assertJsonPath('data.to', '2026-03-16')
            ->assertJsonCount(3, 'data.series')
            ->assertJsonPath('data.totals.orders', 1);
    }

    public function test_non_admin_is_forbidden(): void
    {
        $this->getJson('/api/admin/metrics/timeseries')->assertUnauthorized();

        Sanctum::actingAs(User::factory()->create());
        $this->getJson('/api/admin/metrics/timeseries')->assertForbidden();
    }
}
