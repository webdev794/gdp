<?php

namespace Database\Seeders;

use App\Models\User;
use App\Models\Category;
use App\Models\Product;
use Illuminate\Database\Console\Seeds\WithoutModelEvents;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\Hash;

class DatabaseSeeder extends Seeder
{
    use WithoutModelEvents;

    /**
     * Seed the application's database.
     */
    public function run(): void
    {
        // No factory here so `db:seed` works on a --no-dev install (no Faker).
        User::updateOrCreate(
            ['email' => 'test@example.com'],
            [
                'name' => 'Test User',
                'password' => Hash::make('password'),
                'is_admin' => true,
                'email_verified_at' => now(),
            ]
        );

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

            // image_url points at loremflickr.com, a free keyword-based stock photo
            // service (CC-licensed Flickr photos). `lock` pins one image per product.
            $img = fn (string $keyword, int $lock) => "https://loremflickr.com/400/300/{$keyword}?lock={$lock}";

            $products = match ($category->slug) {
                'fresh-produce' => [
                    ['name' => 'Organic Bananas', 'slug' => 'organic-bananas', 'sku' => 'GDP-PROD-001', 'price_cents' => 299, 'image_url' => $img('banana', 10)],
                    ['name' => 'Gala Apples', 'slug' => 'gala-apples', 'sku' => 'GDP-PROD-002', 'price_cents' => 449, 'image_url' => $img('apple', 20)],
                    ['name' => 'Baby Spinach', 'slug' => 'baby-spinach', 'sku' => 'GDP-PROD-007', 'price_cents' => 349, 'image_url' => $img('spinach', 30)],
                    ['name' => 'Roma Tomatoes', 'slug' => 'roma-tomatoes', 'sku' => 'GDP-PROD-008', 'price_cents' => 279, 'image_url' => $img('tomato', 40)],
                    ['name' => 'Hass Avocados', 'slug' => 'hass-avocados', 'sku' => 'GDP-PROD-009', 'price_cents' => 599, 'image_url' => $img('avocado', 50)],
                ],
                'dairy-and-eggs' => [
                    ['name' => 'Large Brown Eggs', 'slug' => 'large-brown-eggs', 'sku' => 'GDP-PROD-003', 'price_cents' => 599, 'image_url' => $img('eggs', 60)],
                    ['name' => 'Whole Milk', 'slug' => 'whole-milk', 'sku' => 'GDP-PROD-004', 'price_cents' => 429, 'image_url' => $img('milk', 70)],
                    ['name' => 'Greek Yogurt', 'slug' => 'greek-yogurt', 'sku' => 'GDP-PROD-010', 'price_cents' => 519, 'image_url' => $img('yogurt', 80)],
                    ['name' => 'Sharp Cheddar', 'slug' => 'sharp-cheddar', 'sku' => 'GDP-PROD-011', 'price_cents' => 649, 'image_url' => $img('cheese', 90)],
                    ['name' => 'Unsalted Butter', 'slug' => 'unsalted-butter', 'sku' => 'GDP-PROD-012', 'price_cents' => 399, 'image_url' => $img('butter', 100)],
                ],
                default => [
                    ['name' => 'Long Grain Rice', 'slug' => 'long-grain-rice', 'sku' => 'GDP-PROD-005', 'price_cents' => 699, 'image_url' => $img('rice', 110)],
                    ['name' => 'Pasta', 'slug' => 'pasta', 'sku' => 'GDP-PROD-006', 'price_cents' => 249, 'image_url' => $img('pasta', 120)],
                    ['name' => 'Extra Virgin Olive Oil', 'slug' => 'extra-virgin-olive-oil', 'sku' => 'GDP-PROD-013', 'price_cents' => 899, 'image_url' => $img('olive', 130)],
                    ['name' => 'Rolled Oats', 'slug' => 'rolled-oats', 'sku' => 'GDP-PROD-014', 'price_cents' => 459, 'image_url' => $img('oats', 140)],
                    ['name' => 'Peanut Butter', 'slug' => 'peanut-butter', 'sku' => 'GDP-PROD-015', 'price_cents' => 549, 'image_url' => $img('peanut', 150)],
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
