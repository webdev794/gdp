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
       "$DEST/public" "$DEST/database/database.sqlite" \
       "$DEST/web_deploy"  # local deploy staging — never ship it inside the bundle
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

# Android app for direct download on phones: /gdp/downloads/tudee-shopping-center.apk
APK="$SRC/.tmp/deploy/tudee-app-release.apk"
if [ -f "$APK" ]; then
  echo "==> adding Android app download"
  mkdir -p "$DEST/downloads"
  cp "$APK" "$DEST/downloads/tudee-shopping-center.apk"
fi

echo "==> front controller (single-folder layout)"
DEPLOY_TAG=$(date +%Y%m%d%H%M%S)
cat > "$DEST/index.php" <<'PHP'
<?php

use Illuminate\Foundation\Application;
use Illuminate\Http\Request;

define('LARAVEL_START', microtime(true));

// One-time post-deploy self-heal (no shell needed). A cached config/route file
// left by a previous deploy would otherwise keep the old app running. This
// clears the compiled caches and resets OPcache exactly once per bundle, then
// writes a marker so it never runs again.
$deployTag = '__DEPLOY_TAG__';
$deployMark = __DIR__.'/storage/framework/.deployed-'.$deployTag;
$firstRunAfterDeploy = ! is_file($deployMark);
if ($firstRunAfterDeploy) {
    foreach (glob(__DIR__.'/bootstrap/cache/*.php') ?: [] as $stale) { @unlink($stale); }
    foreach (glob(__DIR__.'/storage/framework/views/*.php') ?: [] as $stale) { @unlink($stale); }
    if (function_exists('opcache_reset')) { @opcache_reset(); }
    @file_put_contents($deployMark, $deployTag."\n");
}

if (file_exists($maintenance = __DIR__.'/storage/framework/maintenance.php')) {
    require $maintenance;
}

require __DIR__.'/vendor/autoload.php';

/** @var Application $app */
$app = require_once __DIR__.'/bootstrap/app.php';

// App files and the web root are the same folder in this deployment.
$app->usePublicPath(__DIR__);

// Once per bundle: apply new (additive) database migrations — no Terminal on
// this host. Output goes to storage/logs/deploy-migrate.log.
if ($firstRunAfterDeploy) {
    try {
        $app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
        Illuminate\Support\Facades\Artisan::call('migrate', ['--force' => true]);
        @file_put_contents(__DIR__.'/storage/logs/deploy-migrate.log', date('c').' '.$deployTag."\n".Illuminate\Support\Facades\Artisan::output()."\n", FILE_APPEND);
    } catch (Throwable $e) {
        @file_put_contents(__DIR__.'/storage/logs/deploy-migrate.log', date('c').' FAILED: '.$e->getMessage()."\n", FILE_APPEND);
    }
}

$app->handleRequest(Request::capture());
PHP
sed -i "s/__DEPLOY_TAG__/$DEPLOY_TAG/" "$DEST/index.php"

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

RedirectMatch 404 (?i)/gdp/(app|bootstrap|config|database|resources|routes|vendor|tests)/
RedirectMatch 404 (?i)/gdp/storage/(framework|logs|app)/
<FilesMatch "^(\.env.*|composer\.(json|lock)|artisan|package.*\.json|.*\.md)$">
    Require all denied
</FilesMatch>
# Android app download (/gdp/downloads/*.apk)
AddType application/vnd.android.package-archive .apk
<IfModule mod_headers.c>
    <FilesMatch "\.apk$">
        Header set Content-Disposition "attachment"
    </FilesMatch>
</IfModule>
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
TUDEE SHOPPING CENTER - code update bundle
=============================
Updated application code + built frontend. No .env, no database, no installer -
nothing of yours is touched. Runs as-is: on the first page load after upload,
index.php clears the old compiled caches and resets OPcache by itself, and
applies any new database tables/columns (additive only - existing data is
kept). Result: public_html/gdp/storage/logs/deploy-migrate.log (no Terminal
needed).

DEPLOY
  1. Back up: cPanel > File Manager, download  public_html/gdp/ .
  2. Upload this zip into  public_html/  and Extract, overwrite when asked.
     (Writes into  public_html/gdp/ .)
  3. Make sure  public_html/gdp/.env  exists with your live values
     (DB, APP_URL=https://testcaresortwork.co.in/gdp , APP_KEY, mail, Stripe).
  4. Open  https://testcaresortwork.co.in/gdp/  and hard-refresh (Ctrl+Shift+R).

ANDROID APP (if included): phones download it from
  https://testcaresortwork.co.in/gdp/downloads/tudee-shopping-center.apk
  (Android asks once to allow installing apps from the browser.)

Optional cleanup: in  public_html/gdp/assets/  the old  *-<hash>.js / .css
files no longer named in index.html are just unused bytes - delete anytime.

Rollback: re-upload your  public_html/gdp/  backup.
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
