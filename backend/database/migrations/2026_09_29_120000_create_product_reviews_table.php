<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('product_reviews', function (Blueprint $table) {
            $table->id();
            $table->foreignId('order_id')->constrained()->cascadeOnDelete();
            $table->foreignId('product_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('rating'); // 1..5
            $table->text('comment')->nullable();
            $table->boolean('is_hidden')->default(false); // hidden by admin
            $table->timestamps();

            // Written from an order: one review per product per order.
            $table->unique(['order_id', 'product_id']);
            $table->index(['product_id', 'is_hidden', 'created_at']);
        });

        // Denormalised (visible reviews only) so product lists show stars without
        // re-averaging on every request.
        Schema::table('products', function (Blueprint $table) {
            $table->decimal('rating_avg', 3, 2)->nullable()->after('is_demo');
            $table->unsignedInteger('rating_count')->default(0)->after('rating_avg');
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('product_reviews');
        Schema::table('products', fn (Blueprint $table) => $table->dropColumn(['rating_avg', 'rating_count']));
    }
};
