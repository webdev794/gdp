<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

/**
 * Homepage category tiles are now managed from Admin → Categories. Any custom
 * image set on a tile is copied onto its category so the homepage looks the same.
 */
return new class extends Migration
{
    public function up(): void
    {
        if (! Schema::hasTable('home_tiles')) {
            return;
        }

        $tiles = DB::table('home_tiles')
            ->whereNotNull('category_slug')->where('category_slug', '!=', '')
            ->whereNotNull('image_url')->where('image_url', '!=', '')
            ->orderBy('sort_order')->get(['category_slug', 'image_url']);

        foreach ($tiles->unique('category_slug') as $tile) {
            DB::table('categories')->where('slug', $tile->category_slug)->update(['image_url' => $tile->image_url]);
        }
    }

    public function down(): void
    {
        // Data copy only; nothing to undo.
    }
};
