<?php

namespace Tests\Feature;

use App\Models\Page;
use App\Models\User;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Laravel\Sanctum\Sanctum;
use Tests\TestCase;

class PageTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_index_lists_only_published_pages(): void
    {
        Page::create(['slug' => 'privacy', 'title' => 'Privacy', 'content' => '# hi', 'footer_group' => 'legal', 'sort_order' => 1]);
        Page::create(['slug' => 'draft', 'title' => 'Draft', 'content' => 'wip', 'is_published' => false]);

        $this->getJson('/api/pages')
            ->assertOk()
            ->assertJsonCount(1, 'data')
            ->assertJsonPath('data.0.slug', 'privacy');
    }

    public function test_public_show_returns_content_for_a_published_page_and_404_otherwise(): void
    {
        Page::create(['slug' => 'terms', 'title' => 'Terms', 'content' => '## Terms\n\nBody.']);
        Page::create(['slug' => 'hidden', 'title' => 'Hidden', 'content' => 'x', 'is_published' => false]);

        $this->getJson('/api/pages/terms')
            ->assertOk()
            ->assertJsonPath('data.title', 'Terms')
            ->assertJsonPath('data.content', '## Terms\n\nBody.');

        $this->getJson('/api/pages/hidden')->assertNotFound();
        $this->getJson('/api/pages/nope')->assertNotFound();
    }

    public function test_admin_creates_a_page_and_slug_is_generated_and_deduped(): void
    {
        $admin = User::factory()->create();
        $admin->forceFill(['is_admin' => true])->save();
        Sanctum::actingAs($admin);

        $first = $this->postJson('/api/admin/pages', ['title' => 'Return Policy'])
            ->assertCreated()->json('data');
        $this->assertSame('return-policy', $first['slug']);

        $second = $this->postJson('/api/admin/pages', ['title' => 'Return Policy'])
            ->assertCreated()->json('data');
        $this->assertSame('return-policy-2', $second['slug']);
    }

    public function test_admin_updates_and_deletes_a_page(): void
    {
        $admin = User::factory()->create();
        $admin->forceFill(['is_admin' => true])->save();
        $page = Page::create(['slug' => 'faqs', 'title' => 'FAQs', 'content' => 'old']);
        Sanctum::actingAs($admin);

        $this->patchJson("/api/admin/pages/{$page->id}", ['content' => 'new body', 'is_published' => false])
            ->assertOk()
            ->assertJsonPath('data.content', 'new body')
            ->assertJsonPath('data.is_published', false);

        $this->deleteJson("/api/admin/pages/{$page->id}")->assertNoContent();
        $this->assertDatabaseCount('pages', 0);
    }

    public function test_admin_page_slug_must_be_url_safe(): void
    {
        $admin = User::factory()->create();
        $admin->forceFill(['is_admin' => true])->save();
        Sanctum::actingAs($admin);

        $this->postJson('/api/admin/pages', ['title' => 'X', 'slug' => 'Not A Slug'])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['slug']);
    }

    public function test_non_admin_cannot_manage_pages(): void
    {
        $this->getJson('/api/admin/pages')->assertUnauthorized();

        Sanctum::actingAs(User::factory()->create());
        $this->postJson('/api/admin/pages', ['title' => 'Nope'])->assertForbidden();
    }
}
