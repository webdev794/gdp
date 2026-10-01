<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Reviews now wait for admin approval before they are shown.
        Schema::table('product_reviews', function (Blueprint $table) {
            $table->timestamp('approved_at')->nullable()->after('is_hidden');
        });

        // Reviews that were already public stay public.
        DB::table('product_reviews')->where('is_hidden', false)->whereNull('approved_at')->update(['approved_at' => DB::raw('created_at')]);
    }

    public function down(): void
    {
        Schema::table('product_reviews', fn (Blueprint $table) => $table->dropColumn('approved_at'));
    }
};
