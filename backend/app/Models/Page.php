<?php

namespace App\Models;

use App\Support\PublicMedia;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Database\Eloquent\Model;

class Page extends Model
{
    protected $fillable = [
        'slug', 'title', 'banner_image', 'content', 'sections', 'is_published', 'show_in_footer', 'footer_group', 'sort_order',
    ];

    protected function casts(): array
    {
        return [
            'sections' => 'array',
            'is_published' => 'boolean',
            'show_in_footer' => 'boolean',
            'sort_order' => 'integer',
        ];
    }

    public function getBannerImageAttribute(?string $value): ?string
    {
        return PublicMedia::url($value);
    }

    /**
     * Section blocks can carry image_url at the top level (hero, media_text)
     * or nested in items[] (feature_grid/"cards") — rewrite every occurrence,
     * at any depth, the same way every other image field is.
     */
    public function getSectionsAttribute($value): array
    {
        $sections = is_array($value) ? $value : (json_decode($value ?? '[]', true) ?: []);

        return self::rewriteImageUrls($sections);
    }

    private static function rewriteImageUrls(array $data): array
    {
        foreach ($data as $key => $value) {
            if (is_array($value)) {
                $data[$key] = self::rewriteImageUrls($value);
            } elseif ($key === 'image_url' && is_string($value)) {
                $data[$key] = PublicMedia::url($value);
            }
        }

        return $data;
    }

    public function getRouteKeyName(): string
    {
        return 'id';
    }

    public function scopePublished(Builder $query): Builder
    {
        return $query->where('is_published', true);
    }

    public function scopeOrdered(Builder $query): Builder
    {
        return $query->orderBy('footer_group')->orderBy('sort_order')->orderBy('title');
    }
}
