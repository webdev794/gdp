<?php

namespace Tests\Feature;

use App\Models\Category;
use App\Models\Product;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class AdminProductStatusTest extends TestCase
{
    use RefreshDatabase;

    private function product(string $name, bool $active, bool $demo): void
    {
        $category = Category::firstOrCreate(['slug' => 'misc'], ['name' => 'Misc']);
        Product::create([
            'category_id' => $category->id, 'name' => $name, 'slug' => str($name)->slug(), 'sku' => strtoupper(str($name)->slug()),
            'price_cents' => 100, 'inventory_quantity' => 1, 'is_active' => $active, 'is_demo' => $demo,
        ]);
    }

    public function test_status_tabs_count_and_filter_live_demo_and_draft(): void
    {
        $this->product('Apples', true, false);
        $this->product('Pears', true, false);
        $this->product('Demo Soap', true, true);
        $this->product('Hidden Foil', false, true);
        Sanctum::actingAs(User::factory()->create(['is_admin' => true]));

        $this->getJson('/api/admin/products')
            ->assertOk()
            ->assertJsonPath('meta.status_counts', ['all' => 4, 'live' => 2, 'demo' => 1, 'draft' => 1]);

        $this->getJson('/api/admin/products?status=draft')->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.name', 'Hidden Foil');
        $this->getJson('/api/admin/products?status=demo')->assertJsonPath('meta.total', 1)->assertJsonPath('data.0.name', 'Demo Soap');
        $this->getJson('/api/admin/products?status=live')->assertJsonPath('meta.total', 2);
    }
}
