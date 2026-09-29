<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Demo / sample catalogue flag, so the starter products can be hidden
        // or removed in one go once real products are added.
        Schema::table('products', function (Blueprint $table) {
            $table->boolean('is_demo')->default(false)->after('is_active');
        });

        // The seeded starter catalogue uses GDP-PROD-### SKUs; flag those only.
        DB::table('products')->where('sku', 'like', 'GDP-PROD-%')->update(['is_demo' => true]);
    }

    public function down(): void
    {
        Schema::table('products', fn (Blueprint $table) => $table->dropColumn('is_demo'));
    }
};
