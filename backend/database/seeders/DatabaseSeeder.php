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

        // Free ingredient photos from TheMealDB (public, no key, white background).
        $img = fn (string $ingredient) => 'https://www.themealdb.com/images/ingredients/'
            . rawurlencode($ingredient) . '-Medium.png';

        $categories = [
            ['name' => 'Fresh Produce', 'slug' => 'fresh-produce', 'sort_order' => 1, 'image_url' => $img('Tomato')],
            ['name' => 'Dairy and Eggs', 'slug' => 'dairy-and-eggs', 'sort_order' => 2, 'image_url' => $img('Milk')],
            ['name' => 'Pantry Staples', 'slug' => 'pantry-staples', 'sort_order' => 3, 'image_url' => $img('Rice')],
        ];

        foreach ($categories as $categoryData) {
            $category = Category::updateOrCreate(
                ['slug' => $categoryData['slug']],
                $categoryData
            );

            $products = match ($category->slug) {
                'fresh-produce' => [
                    ['name' => 'Organic Bananas', 'slug' => 'organic-bananas', 'sku' => 'GDP-PROD-001', 'price_cents' => 299, 'image_url' => $img('Banana')],
                    ['name' => 'Gala Apples', 'slug' => 'gala-apples', 'sku' => 'GDP-PROD-002', 'price_cents' => 449, 'image_url' => $img('Apples')],
                    ['name' => 'Baby Spinach', 'slug' => 'baby-spinach', 'sku' => 'GDP-PROD-007', 'price_cents' => 349, 'image_url' => $img('Spinach')],
                    ['name' => 'Roma Tomatoes', 'slug' => 'roma-tomatoes', 'sku' => 'GDP-PROD-008', 'price_cents' => 279, 'image_url' => $img('Tomato')],
                    ['name' => 'Hass Avocados', 'slug' => 'hass-avocados', 'sku' => 'GDP-PROD-009', 'price_cents' => 599, 'image_url' => $img('Avocado')],
                ],
                'dairy-and-eggs' => [
                    ['name' => 'Large Brown Eggs', 'slug' => 'large-brown-eggs', 'sku' => 'GDP-PROD-003', 'price_cents' => 599, 'image_url' => $img('Egg')],
                    ['name' => 'Whole Milk', 'slug' => 'whole-milk', 'sku' => 'GDP-PROD-004', 'price_cents' => 429, 'image_url' => $img('Milk')],
                    ['name' => 'Greek Yogurt', 'slug' => 'greek-yogurt', 'sku' => 'GDP-PROD-010', 'price_cents' => 519, 'image_url' => $img('Yogurt')],
                    ['name' => 'Sharp Cheddar', 'slug' => 'sharp-cheddar', 'sku' => 'GDP-PROD-011', 'price_cents' => 649, 'image_url' => $img('Cheddar Cheese')],
                    ['name' => 'Unsalted Butter', 'slug' => 'unsalted-butter', 'sku' => 'GDP-PROD-012', 'price_cents' => 399, 'image_url' => $img('Butter')],
                ],
                default => [
                    ['name' => 'Long Grain Rice', 'slug' => 'long-grain-rice', 'sku' => 'GDP-PROD-005', 'price_cents' => 699, 'image_url' => $img('Rice')],
                    ['name' => 'Pasta', 'slug' => 'pasta', 'sku' => 'GDP-PROD-006', 'price_cents' => 249, 'image_url' => $img('Spaghetti')],
                    ['name' => 'Extra Virgin Olive Oil', 'slug' => 'extra-virgin-olive-oil', 'sku' => 'GDP-PROD-013', 'price_cents' => 899, 'image_url' => $img('Olive Oil')],
                    ['name' => 'Rolled Oats', 'slug' => 'rolled-oats', 'sku' => 'GDP-PROD-014', 'price_cents' => 459, 'image_url' => $img('Oats')],
                    ['name' => 'Peanut Butter', 'slug' => 'peanut-butter', 'sku' => 'GDP-PROD-015', 'price_cents' => 549, 'image_url' => $img('Peanut Butter')],
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
