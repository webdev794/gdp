<?php

namespace Database\Seeders;

use App\Models\Banner;
use App\Models\HomeTile;
use App\Models\Page;
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
            ['name' => 'Test User', 'phone' => '+15551234567', 'password' => Hash::make('password'), 'email_verified_at' => now()]
        )->forceFill(['is_admin' => true])->save();

        User::updateOrCreate(
            ['email' => 'rider@example.com'],
            ['name' => 'Sam Rider', 'password' => Hash::make('password'), 'email_verified_at' => now()]
        )->forceFill(['is_rider' => true])->save();

        // Free ingredient photos from TheMealDB (public, no key, white background).
        $img = fn (?string $ingredient) => $ingredient === null ? null
            : 'https://www.themealdb.com/images/ingredients/' . rawurlencode($ingredient) . '-Medium.png';

        // [display name, stable slug, category image (null = emoji tile), [ [product, sku, price_cents, image], ... ] ]
        // Names mirror Blinkit; the slug never changes so re-seeding just refreshes
        // the name on the existing row. Tiles fall back to a per-category emoji;
        // upload real artwork per tile in Admin -> Homepage -> Category tiles.
        // SKUs 001-015 unchanged.
        $catalog = [
            ['Fruits & Vegetables', 'fresh-produce', null, [
                ['Organic Bananas', 'GDP-PROD-001', 299, 'Banana'],
                ['Gala Apples', 'GDP-PROD-002', 449, 'Apples'],
                ['Baby Spinach', 'GDP-PROD-007', 349, 'Spinach'],
                ['Roma Tomatoes', 'GDP-PROD-008', 279, 'Tomato'],
                ['Hass Avocados', 'GDP-PROD-009', 599, 'Avocado'],
            ]],
            ['Dairy, Bread & Eggs', 'dairy-and-eggs', null, [
                ['Large Brown Eggs', 'GDP-PROD-003', 599, 'Egg'],
                ['Whole Milk', 'GDP-PROD-004', 429, 'Milk'],
                ['Greek Yogurt', 'GDP-PROD-010', 519, 'Yogurt'],
                ['Sharp Cheddar', 'GDP-PROD-011', 649, 'Cheddar Cheese'],
                ['Unsalted Butter', 'GDP-PROD-012', 399, 'Butter'],
            ]],
            ['Atta, Rice & Dal', 'pantry-staples', null, [
                ['Long Grain Rice', 'GDP-PROD-005', 699, 'Rice'],
                ['Pasta', 'GDP-PROD-006', 249, 'Spaghetti'],
                ['Extra Virgin Olive Oil', 'GDP-PROD-013', 899, 'Olive Oil'],
                ['Rolled Oats', 'GDP-PROD-014', 459, 'Oats'],
                ['Peanut Butter', 'GDP-PROD-015', 549, 'Peanut Butter'],
            ]],
            ['Snacks & Munchies', 'snacks-and-munchies', null, [
                ['Salted Potato Chips', 'GDP-PROD-016', 199, null],
                ['Butter Popcorn', 'GDP-PROD-017', 249, null],
                ['Roasted Trail Mix', 'GDP-PROD-018', 549, null],
            ]],
            ['Cold Drinks & Juices', 'beverages', null, [
                ['Orange Juice', 'GDP-PROD-019', 399, 'Orange'],
                ['Sparkling Water', 'GDP-PROD-020', 149, 'Water'],
                ['Cola 6-Pack', 'GDP-PROD-021', 499, null],
            ]],
            ['Bakery & Biscuits', 'bakery-and-breads', null, [
                ['Sourdough Loaf', 'GDP-PROD-022', 449, 'Bread'],
                ['Burger Buns', 'GDP-PROD-023', 279, null],
                ['Butter Croissants', 'GDP-PROD-024', 399, null],
            ]],
            ['Breakfast & Instant Food', 'breakfast-and-cereal', null, [
                ['Corn Flakes', 'GDP-PROD-025', 429, null],
                ['Honey Granola', 'GDP-PROD-026', 549, null],
                ['Pancake Mix', 'GDP-PROD-027', 389, 'Flour'],
            ]],
            ['Sweet Tooth', 'sweets-and-chocolate', null, [
                ['Dark Chocolate Bar', 'GDP-PROD-028', 299, null],
                ['Choc Chip Cookies', 'GDP-PROD-029', 349, null],
                ['Gummy Bears', 'GDP-PROD-030', 199, null],
            ]],
            ['Chicken, Meat & Fish', 'meat-and-seafood', null, [
                ['Chicken Breast', 'GDP-PROD-031', 899, 'Chicken'],
                ['Salmon Fillet', 'GDP-PROD-032', 1299, 'Salmon'],
                ['Pork Sausages', 'GDP-PROD-033', 649, null],
            ]],
            ['Frozen Foods', 'frozen-foods', null, [
                ['Frozen Peas', 'GDP-PROD-034', 249, null],
                ['Vanilla Ice Cream', 'GDP-PROD-035', 549, null],
                ['Crispy Fries', 'GDP-PROD-036', 399, null],
            ]],
            ['Tea, Coffee & Health Drink', 'tea-and-coffee', null, [
                ['Ground Coffee', 'GDP-PROD-037', 899, 'Coffee'],
                ['Green Tea Bags', 'GDP-PROD-038', 449, null],
                ['Masala Chai', 'GDP-PROD-039', 399, null],
            ]],
            ['Sauces & Spreads', 'sauces-and-spreads', null, [
                ['Tomato Ketchup', 'GDP-PROD-040', 249, null],
                ['Mayonnaise', 'GDP-PROD-041', 329, null],
                ['Strawberry Jam', 'GDP-PROD-042', 299, null],
            ]],
            ['Cleaning Essentials', 'cleaning-essentials', null, [
                ['Dish Soap', 'GDP-PROD-043', 279, null],
                ['Laundry Detergent', 'GDP-PROD-044', 899, null],
                ['Surface Cleaner', 'GDP-PROD-045', 349, null],
            ]],
            ['Personal Care', 'personal-care', null, [
                ['Shampoo', 'GDP-PROD-046', 549, null],
                ['Toothpaste', 'GDP-PROD-047', 199, null],
                ['Hand Soap', 'GDP-PROD-048', 249, null],
            ]],
            ['Baby Care', 'baby-care', null, [
                ['Diapers Value Pack', 'GDP-PROD-049', 1499, null],
                ['Baby Wipes', 'GDP-PROD-050', 299, null],
                ['Baby Lotion', 'GDP-PROD-051', 449, null],
            ]],
            ['Home & Office', 'home-and-kitchen', null, [
                ['Paper Towels', 'GDP-PROD-052', 399, null],
                ['Trash Bags', 'GDP-PROD-053', 349, null],
                ['Aluminium Foil', 'GDP-PROD-054', 299, null],
            ]],
            ['Paan Corner', 'paan-corner', null, []],
            ['Pharma & Wellness', 'pharma-wellness', null, []],
            ['Organic & Premium', 'organic-premium', null, []],
            ['Pet Care', 'pet-care', null, []],
        ];

        foreach ($catalog as $index => [$name, $slug, $categoryImage, $products]) {
            $category = Category::updateOrCreate(
                ['slug' => $slug],
                ['name' => $name, 'sort_order' => $index + 1, 'image_url' => "/img/cat/{$slug}.png"]
            );

            foreach ($products as [$productName, $sku, $priceCents, $productImage]) {
                Product::updateOrCreate(
                    ['sku' => $sku],
                    [
                        'name' => $productName,
                        'slug' => \Illuminate\Support\Str::slug($productName),
                        'price_cents' => $priceCents,
                        'image_url' => $img($productImage),
                        'category_id' => $category->id,
                        'inventory_quantity' => 100,
                    ]
                );
            }
        }

        // A few demo items go "on sale" so the strike-through pricing is visible.
        Product::whereIn('sku', ['GDP-PROD-002', 'GDP-PROD-010', 'GDP-PROD-028', 'GDP-PROD-044'])->get()
            ->each(fn (Product $p) => $p->update(['compare_at_price_cents' => (int) round($p->price_cents / 0.8)]));

        $this->seedVariants();
        $this->seedBanners();
        $this->seedHomeTiles();
        $this->seedPages();
    }

    /**
     * Starter content pages for the storefront footer. Content is Markdown and
     * is meant to be replaced by the store owner in Admin console -> Pages.
     */
    private function seedPages(): void
    {
        $pages = [
            ['slug' => 'about', 'title' => 'About Us', 'footer_group' => 'company', 'sort_order' => 1,
                'content' => "## About Grocerly\n\nGrocerly delivers everyday groceries and household essentials to your door, fast.\n\nEdit this page in **Admin console -> Pages**."],
            ['slug' => 'blog', 'title' => 'Blog', 'footer_group' => 'company', 'sort_order' => 2,
                'content' => "## Blog\n\nStories, recipes and updates from the Grocerly team. Add posts here or link out to a dedicated blog."],
            ['slug' => 'contact', 'title' => 'Contact Us', 'footer_group' => 'company', 'sort_order' => 3,
                'content' => "## Contact\n\n- Email: support@grocerly.example\n- Hours: 8am - 10pm, every day\n\nFor help with a specific order, use **Get help** on the order in your account."],
            ['slug' => 'faqs', 'title' => 'FAQs', 'footer_group' => 'help', 'sort_order' => 1,
                'content' => "## Frequently asked questions\n\n### How fast is delivery?\nMost orders arrive within the delivery window shown at checkout.\n\n### Which areas do you serve?\nEnter your address on the home page to check serviceability.\n\n### How do refunds work?\nRaise an issue from your order history; refunds are reviewed and issued to the original payment method."],
            ['slug' => 'privacy', 'title' => 'Privacy Policy', 'footer_group' => 'legal', 'sort_order' => 1,
                'content' => "## Privacy Policy\n\nThis is placeholder text. Describe what data you collect, how it is used, and how customers can request deletion.\n\nReplace this content in Admin console -> Pages."],
            ['slug' => 'terms', 'title' => 'Terms of Service', 'footer_group' => 'legal', 'sort_order' => 2,
                'content' => "## Terms of Service\n\nThis is placeholder text. Set out the rules for using the service, ordering, pricing, cancellations and liability.\n\nReplace this content in Admin console -> Pages."],
            ['slug' => 'security', 'title' => 'Security', 'footer_group' => 'legal', 'sort_order' => 3,
                'content' => "## Security\n\nHow we protect payments and accounts. Payments are processed by Stripe; card details never touch our servers."],
        ];

        foreach ($pages as $page) {
            Page::updateOrCreate(['slug' => $page['slug']], [
                ...$page,
                'is_published' => true,
                'show_in_footer' => true,
            ]);
        }
    }

    /**
     * Start the curated homepage tile list as a mirror of the categories, in
     * order. An admin trims / reorders / re-images these in the Homepage editor;
     * with no active tiles the storefront falls back to listing every category.
     */
    private function seedHomeTiles(): void
    {
        foreach (Category::query()->orderBy('sort_order')->get() as $index => $category) {
            HomeTile::updateOrCreate(
                ['category_slug' => $category->slug],
                ['sort_order' => $index + 1, 'is_active' => true]
            );
        }
    }

    /**
     * A few homepage banners so the storefront's promo strip is populated out of
     * the box. Images are public Blinkit layout assets (illustrative only).
     */
    private function seedBanners(): void
    {
        $banners = [
            [
                'image_url' => 'https://cdn.grofers.com/cdn-cgi/image/f=auto,fit=scale-down,q=70,metadata=none,w=2700/layout-engine/2026-01/Frame-1437256605-2-2.jpg',
                'headline' => null,
                'category_slug' => 'fresh-produce',
                'placement' => 'hero',
                'sort_order' => 1,
            ],
            [
                'image_url' => 'https://cdn.grofers.com/cdn-cgi/image/f=auto,fit=scale-down,q=70,metadata=none,w=720/layout-engine/2023-07/pharmacy-WEB.jpg',
                'headline' => null,
                'category_slug' => 'personal-care',
                'placement' => 'strip',
                'sort_order' => 2,
            ],
            [
                'image_url' => 'https://cdn.grofers.com/cdn-cgi/image/f=auto,fit=scale-down,q=70,metadata=none,w=720/layout-engine/2026-01/pet_crystal_WEB-1.png',
                'headline' => null,
                'category_slug' => 'home-and-kitchen',
                'placement' => 'strip',
                'sort_order' => 3,
            ],
            [
                'image_url' => 'https://cdn.grofers.com/cdn-cgi/image/f=auto,fit=scale-down,q=70,metadata=none,w=720/layout-engine/2026-01/baby_crystal_WEB-1.png',
                'headline' => null,
                'category_slug' => 'baby-care',
                'placement' => 'strip',
                'sort_order' => 4,
            ],
        ];

        foreach ($banners as $banner) {
            Banner::updateOrCreate(['image_url' => $banner['image_url']], $banner);
        }
    }

    /**
     * A couple of demo products get Blinkit-style pack sizes so the variant
     * selector is visible out of the box. Everything else stays single-price.
     */
    private function seedVariants(): void
    {
        $packs = [
            'GDP-PROD-004' => [ // Whole Milk
                ['label' => '500 ml', 'sku' => 'GDP-PROD-004-500', 'price_cents' => 249, 'inventory_quantity' => 80, 'sort_order' => 1],
                ['label' => '1 L', 'sku' => 'GDP-PROD-004-1000', 'price_cents' => 429, 'inventory_quantity' => 60, 'sort_order' => 2],
                ['label' => '2 L', 'sku' => 'GDP-PROD-004-2000', 'price_cents' => 799, 'inventory_quantity' => 30, 'sort_order' => 3],
            ],
            'GDP-PROD-005' => [ // Long Grain Rice
                ['label' => '1 kg', 'sku' => 'GDP-PROD-005-1KG', 'price_cents' => 699, 'inventory_quantity' => 50, 'sort_order' => 1],
                ['label' => '5 kg', 'sku' => 'GDP-PROD-005-5KG', 'price_cents' => 3199, 'inventory_quantity' => 15, 'sort_order' => 2],
            ],
        ];

        foreach ($packs as $productSku => $variants) {
            $product = Product::where('sku', $productSku)->first();
            if (! $product) {
                continue;
            }

            foreach ($variants as $variant) {
                $product->variants()->updateOrCreate(['sku' => $variant['sku']], $variant);
            }
        }
    }
}
