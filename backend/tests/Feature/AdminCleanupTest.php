<?php

namespace Tests\Feature;

use App\Models\Address;
use App\Models\Category;
use App\Models\Order;
use App\Models\Product;
use App\Models\Store;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminCleanupTest extends TestCase
{
    use RefreshDatabase;

    private function product(string $name, ?string $image): Product
    {
        $category = Category::firstOrCreate(['slug' => 'misc'], ['name' => 'Misc']);

        return Product::create([
            'category_id' => $category->id, 'name' => $name, 'slug' => str($name)->slug(), 'sku' => strtoupper(str($name)->slug()),
            'price_cents' => 100, 'inventory_quantity' => 5, 'is_active' => true, 'image_url' => $image,
        ]);
    }

    public function test_products_without_any_image_are_removed_and_ordered_ones_hidden(): void
    {
        $withImage = $this->product('Apples', '/api/media/file/products/a.png');
        $gallery = $this->product('Pears', null);
        $gallery->images()->create(['image_url' => '/api/media/file/products/p.png', 'sort_order' => 0]);
        $noImage = $this->product('Shampoo', null);
        $ordered = $this->product('Soap', '');

        $order = Order::create([
            'user_id' => User::factory()->create()->id, 'status' => 'completed', 'payment_status' => 'paid', 'payment_method' => 'card',
            'subtotal_cents' => 100, 'tax_cents' => 0, 'delivery_fee_cents' => 0, 'total_cents' => 100,
            'delivery_address' => ['name' => 'C', 'line1' => '1', 'city' => 'Kakata', 'state' => 'Margibi', 'postal_code' => ''],
        ]);
        $order->items()->create(['product_id' => $ordered->id, 'product_name' => 'Soap', 'sku' => 'SOAP', 'quantity' => 1, 'unit_price_cents' => 100, 'line_total_cents' => 100]);

        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));
        $this->postJson('/api/admin/products/delete-without-images')
            ->assertOk()
            ->assertJsonPath('data.deleted', 1)
            ->assertJsonPath('data.hidden', 1);

        $this->assertNotNull($withImage->fresh());
        $this->assertNotNull($gallery->fresh());
        $this->assertNull($noImage->fresh());
        $this->assertFalse($ordered->fresh()->is_active);
    }

    public function test_saved_addresses_outside_every_store_radius_are_removed(): void
    {
        Store::create(['name' => 'Kakata', 'line1' => 'Kakata', 'city' => 'Kakata', 'state' => 'Margibi', 'postal_code' => '', 'latitude' => 6.53189, 'longitude' => -10.349486, 'delivery_radius_km' => 5, 'is_active' => true]);
        $user = User::factory()->create();
        $base = ['user_id' => $user->id, 'label' => 'Home', 'name' => 'C', 'line1' => '1 Road', 'city' => 'X', 'state' => 'Y', 'postal_code' => ''];
        $near = Address::create($base + ['latitude' => 6.5303, 'longitude' => -10.3505]);   // Kakata, < 1 km
        $mohali = Address::create($base + ['latitude' => 30.7149, 'longitude' => 76.7227]); // India
        $noPin = Address::create($base + ['latitude' => null, 'longitude' => null]);

        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));
        $this->postJson('/api/admin/addresses/prune-outside-area')
            ->assertOk()
            ->assertJsonPath('data.deleted', 2);

        $this->assertNotNull($near->fresh());
        $this->assertNull($mohali->fresh());
        $this->assertNull($noPin->fresh()); // no pin = cannot be checked or delivered
    }

    public function test_customers_cannot_run_cleanups(): void
    {
        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/admin/products/delete-without-images')->assertForbidden();
        $this->postJson('/api/admin/addresses/prune-outside-area')->assertForbidden();
    }
}
