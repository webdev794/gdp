#!/usr/bin/env bash
# Redeploy bundle: updated code only. Unlike build-deploy.sh this does NOT ship a
# .env or _setup.php, so extracting it over an existing install keeps the live
# config and database untouched.
set -euo pipefail

SRC=/d/gdp
STAGE=/d/gdp/.tmp/deploy/stage-update
OUT=/d/gdp/.tmp/deploy/gdp-cpanel-update.zip

rm -rf "$STAGE" "$OUT"
mkdir -p "$STAGE/gdp"
DEST="$STAGE/gdp"

echo "==> copying Laravel app"
cd "$SRC/backend"
cp -a ./ "$DEST/"
rm -rf "$DEST/.git" "$DEST/node_modules" "$DEST/tests" "$DEST/phpunit.xml" \
       "$DEST/.phpunit.result.cache" "$DEST/.phpunit.cache" "$DEST/.env" "$DEST/.env.example" \
       "$DEST/public" "$DEST/database/database.sqlite"
rm -f  "$DEST/storage/logs/"*.log
rm -rf "$DEST/storage/framework/cache/data/"* \
       "$DEST/storage/framework/sessions/"* \
       "$DEST/storage/framework/views/"*.php \
       "$DEST/storage/framework/testing" 2>/dev/null || true
rm -f  "$DEST/bootstrap/cache/"*.php
# storage/app is runtime data on the server (uploaded media) — never ship it
rm -rf "$DEST/storage/app" 2>/dev/null || true

echo "==> merging built React storefront"
cp -r "$SRC/web/dist/." "$DEST/"

echo "==> front controller (single-folder layout)"
cat > "$DEST/index.php" <<'PHP'
<?php

use Illuminate\Foundation\Application;
use Illuminate\Http\Request;

define('LARAVEL_START', microtime(true));

if (file_exists($maintenance = __DIR__.'/storage/framework/maintenance.php')) {
    require $maintenance;
}

require __DIR__.'/vendor/autoload.php';

/** @var Application $app */
$app = require_once __DIR__.'/bootstrap/app.php';

// App files and the web root are the same folder in this deployment.
$app->usePublicPath(__DIR__);

$app->handleRequest(Request::capture());
PHP

echo "==> .htaccess"
cat > "$DEST/.htaccess" <<'HTACCESS'
<IfModule mod_rewrite.c>
    <IfModule mod_negotiation.c>
        Options -MultiViews -Indexes
    </IfModule>

    RewriteEngine On
    RewriteBase /gdp/

    DirectoryIndex index.php

    RewriteCond %{HTTP:Authorization} .
    RewriteRule .* - [E=HTTP_AUTHORIZATION:%{HTTP:Authorization}]
    RewriteCond %{HTTP:x-xsrf-token} .
    RewriteRule .* - [E=HTTP_X_XSRF_TOKEN:%{HTTP:X-XSRF-Token}]

    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_URI} (.+)/$
    RewriteRule ^ %1 [L,R=301]

    RewriteCond %{REQUEST_FILENAME} !-d
    RewriteCond %{REQUEST_FILENAME} !-f
    RewriteRule ^ index.php [L]
</IfModule>

RedirectMatch 404 (?i)/gdp/(app|bootstrap|config|database|resources|routes|storage|vendor|tests)/
<FilesMatch "^(\.env.*|composer\.(json|lock)|artisan|package.*\.json|.*\.md)$">
    Require all denied
</FilesMatch>
HTACCESS

echo "==> writing runtime dirs (empty — server keeps its own)"
mkdir -p "$DEST/storage/framework/cache/data" \
         "$DEST/storage/framework/sessions" \
         "$DEST/storage/framework/views" \
         "$DEST/storage/logs" \
         "$DEST/storage/app/public" \
         "$DEST/bootstrap/cache"
find "$DEST/storage" "$DEST/bootstrap/cache" -name '.gitignore' -delete 2>/dev/null || true

echo "==> READ_ME_FIRST.txt"
cat > "$STAGE/READ_ME_FIRST.txt" <<'TXT'
GROCERLY - update bundle (v7)
=============================
This bundle contains updated CODE ONLY. It has no .env and no installer, so it
will not touch your live configuration or data.

WHAT'S NEW (latest)
  - Rider delivery OFFERS: 60s accept/reject prompt with looping alarm;
    reject/timeout re-offers to the next rider or drops to the pool
  - Rider attendance: clock in / lunch break / clock out, availability that
    gates auto-assign, unavailable-with-reason, monthly attendance report
  - Rider metrics: rejected / missed counts + acceptance rate
  - "Order delivered" email to the customer with the PDF bill attached
  - Admin: order summary drawer, cancel a stuck pending-payment order,
    Formatting guide tab, product category filter, loading spinners,
    table / tab / spacing polish
  - Storefront: loads the whole catalogue (not just the first page)
  - Self-hosted Okra font; page body renders *italic*

NEW DATABASE OBJECTS (already in your local DB, so your full import covers them):
  - tables  rider_shifts, rider_shift_breaks, rider_reviews, store_inventory
  - orders  rider_offer_expires_at, rider_accepted_at, rider_offer_declined_ids,
            rider_offer_decline_count, receipt_emailed_at, store_id,
            delivered_at, delivery_verified, delivery_note, delivery_code,
            delivery_code_expires_at
  - users   rider_available, rider_unavailable_reason, rider_last_seen_at,
            rider_offers_count, rider_declined_count, rider_missed_count,
            rider_daily_target_minutes, rider_since, rider_rating_avg,
            rider_rating_count, + the v7-base rider_* columns
  - support_threads  rating, rating_comment, rated_at
  If you import the full local DB you are covered. To apply only the schema to
  existing live data instead, run:  php artisan migrate --force

STEPS
  1. Back up first: in cPanel download public_html/gdp/  and export the DB.
  2. cPanel > File Manager > open  public_html/
     Upload this zip INTO public_html/  and Extract  ->  overwrite when asked.
     (It writes into public_html/gdp/ ; your .env is NOT in the zip.)
  3. Delete stale hashed assets: in  public_html/gdp/assets/  remove files whose
     names are not referenced by the new index.html (old *-<hash>.js / .css).
  4. Clear the caches (cPanel > Terminal), so the new config/routes take:
         cd ~/public_html/gdp
         rm -f bootstrap/cache/*.php
         php artisan config:clear && php artisan route:clear && php artisan cache:clear
  5. *** BRING THE DATABASE UP TO DATE — REQUIRED ***
     The new code reads columns/tables that older live data doesn't have
     (rider_last_seen_at, rider_shifts, orders.receipt_emailed_at, ...); without
     this step every /rider/* call 500s. Do ONE of:
       a) finish importing the full local DB (it already has everything), OR
       b) run the migrations on the existing live data:
             cd ~/public_html/gdp && php artisan migrate --force
  6. Hard-refresh  https://testcaresortwork.co.in/gdp/  (Ctrl+Shift+R).

Rollback: re-upload your backup of public_html/gdp/ and re-import the DB dump.
TXT

echo "==> zipping"
if command -v zip >/dev/null 2>&1; then
  cd "$STAGE"
  zip -qr "$OUT" gdp READ_ME_FIRST.txt -x '*/.DS_Store'
else
  # PowerShell's Compress-Archive writes backslash paths that cPanel mis-extracts.
  # Use PHP's ZipArchive, which writes spec-correct forward slashes.
  STAGE_WIN=$(cygpath -w "$STAGE" 2>/dev/null || echo "$STAGE")
  OUT_WIN=$(cygpath -w "$OUT" 2>/dev/null || echo "$OUT")
  STAGE_PHP=${STAGE_WIN//\\//}
  OUT_PHP=${OUT_WIN//\\//}
  php -r '
    $stage = $argv[1]; $out = $argv[2];
    @unlink($out);
    $zip = new ZipArchive();
    if ($zip->open($out, ZipArchive::CREATE | ZipArchive::OVERWRITE) !== true) { fwrite(STDERR, "cannot open zip\n"); exit(1); }
    $it = new RecursiveIteratorIterator(new RecursiveDirectoryIterator($stage, FilesystemIterator::SKIP_DOTS), RecursiveIteratorIterator::SELF_FIRST);
    $n = 0;
    foreach ($it as $f) {
        $rel = substr(str_replace("\\", "/", $f->getPathname()), strlen($stage) + 1);
        if ($f->isDir()) { $zip->addEmptyDir($rel); }
        else { $zip->addFile($f->getPathname(), $rel); $n++; }
    }
    $zip->close();
    echo "files: $n\n";
  ' "$STAGE_PHP" "$OUT_PHP"
fi

echo
echo "BUILT: $OUT"
du -h "$OUT" | cut -f1
