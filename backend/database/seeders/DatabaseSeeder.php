<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        User::factory()->create([
            'name' => 'Test User',
            'email' => 'test@example.com',
            'is_admin' => true,
        ]);

        $categories = [
            ['name' => 'Fresh Produce', 'slug' => 'fresh-produce', 'sort_order' => 1],
            ['name' => 'Dairy and Eggs', 'slug' => 'dairy-and-eggs', 'sort_order' => 2],
            ['name' => 'Pantry Staples', 'slug' => 'pantry-staples', 'sort_order' => 3],
        ];

        foreach ($categories as $categoryData) {
            $category = Category::updateOrCreate(
                ['slug' => $categoryData['slug']],
                $categoryData
            );

            $products = match ($category->slug) {
                'fresh-produce' => [
                    ['name' => 'Organic Bananas', 'slug' => 'organic-bananas', 'sku' => 'GDP-PROD-001', 'price_cents' => 299],
                    ['name' => 'Gala Apples', 'slug' => 'gala-apples', 'sku' => 'GDP-PROD-002', 'price_cents' => 449],
                ],
                'dairy-and-eggs' => [
                    ['name' => 'Large Brown Eggs', 'slug' => 'large-brown-eggs', 'sku' => 'GDP-PROD-003', 'price_cents' => 599],
                    ['name' => 'Whole Milk', 'slug' => 'whole-milk', 'sku' => 'GDP-PROD-004', 'price_cents' => 429],
                ],
                default => [
                    ['name' => 'Long Grain Rice', 'slug' => 'long-grain-rice', 'sku' => 'GDP-PROD-005', 'price_cents' => 699],
                    ['name' => 'Pasta', 'slug' => 'pasta', 'sku' => 'GDP-PROD-006', 'price_cents' => 249],
                ],
            };

            foreach ($products as $productData) {
                Product::updateOrCreate(
                    ['sku' => $productData['sku']],
                    [...$productData, 'category_id' => $category->id, 'inventory_quantity' => 100]
                );
            }
        }
    }
}
