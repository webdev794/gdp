# Deploying to cPanel at `https://testcaresortwork.co.in/gdp/`

The Laravel API and the React storefront are served from the **same path**:

- `https://testcaresortwork.co.in/gdp/`        → React storefront + admin console
- `https://testcaresortwork.co.in/gdp/api/...` → Laravel API

No sub‑domain, no CORS (same origin), one MySQL database. Auth is Bearer‑token, so there
are no cookie/session/CSRF concerns across origins.

## Layout on the server

```
/home/<cpuser>/
├── gdp-app/                     Laravel application (NOT web-accessible)
│   ├── app/  bootstrap/  config/  database/  routes/  vendor/  ...
│   └── .env                     production settings (see below)
└── public_html/
    └── gdp/                     web root for /gdp/
        ├── index.php            Laravel front controller (paths patched)
        ├── .htaccess            from backend/public/.htaccess
        ├── index.html           React entry (served by Laravel fallback)
        ├── assets/              React JS/CSS  (from web/dist/assets/)
        ├── favicon.svg  ...     other web/dist files
        └── build/  hot  storage (Laravel's own public assets, if any)
```

---

## 1. Build locally

### Backend vendor

```cmd
cd /d D:\gdp\backend
composer install --no-dev --optimize-autoloader
```

(If you have no local Composer, install deps on the server in step 4 instead.)

### Frontend

`web/.env.production` is already set to `VITE_BASE=/gdp/` and `VITE_API_URL=/gdp/api`.

```cmd
cd /d D:\gdp\web
npm.cmd --cache D:\gdp\.tmp\npm-cache install
npm.cmd --cache D:\gdp\.tmp\npm-cache run build
```

Output is `web/dist/` with asset URLs under `/gdp/`.

---

## 2. Create the database (cPanel → MySQL® Databases)

1. Create database `<cpuser>_gdp`.
2. Create a user, give it **All Privileges** on that database.
3. Note the name, user, password — they go in `.env`.

---

## 3. Set the PHP version (cPanel → MultiPHP Manager)

Set `public_html/gdp` (or the whole account) to **PHP 8.3** (8.2 minimum).
In **MultiPHP INI Editor** make sure these extensions are on: `pdo_mysql`, `mbstring`,
`openssl`, `curl`, `fileinfo`, `bcmath`, `ctype`, `tokenizer`, `xml`.

---

## 4. Upload

Using cPanel File Manager (or SFTP / Git):

1. Upload the **backend** to `/home/<cpuser>/gdp-app/` — everything in `backend/` **except**
   `node_modules`, `tests`, `.git`. Include `vendor/` if you built it in step 1.
2. Upload the **contents of `backend/public/`** into `public_html/gdp/`.
3. Upload the **contents of `web/dist/`** into `public_html/gdp/` (merge — `assets/`,
   `index.html`, `favicon.svg`, …). If `web/dist/index.html` and any Laravel file clash,
   keep both; `index.html` is fine to sit next to `index.php`.

### Patch `public_html/gdp/index.php`

Change the two `require` paths so they point at the app folder:

```php
// was: __DIR__.'/../vendor/autoload.php'
require __DIR__.'/../../gdp-app/vendor/autoload.php';

// was: __DIR__.'/../bootstrap/app.php'
$app = require_once __DIR__.'/../../gdp-app/bootstrap/app.php';
```

Also add near the top of `index.php`, right after `<?php`:

```php
$_SERVER['SCRIPT_FILENAME'] = __FILE__;
```

### `public_html/gdp/.htaccess`

Use the one from `backend/public/.htaccess` as‑is. Add this line inside the
`<IfModule mod_rewrite.c>` block so rewrites resolve under the sub‑folder:

```apache
RewriteBase /gdp/
```

---

## 5. Configure `/home/<cpuser>/gdp-app/.env`

Start from `backend/.env.example` and set:

```env
APP_NAME=Grocerly
APP_ENV=production
APP_DEBUG=false
APP_URL=https://testcaresortwork.co.in/gdp
ASSET_URL=https://testcaresortwork.co.in/gdp

APP_KEY=                      # generate in step 6

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=<cpuser>_gdp
DB_USERNAME=<cpuser>_gdpuser
DB_PASSWORD=<the password>

SESSION_DRIVER=file
CACHE_STORE=file
QUEUE_CONNECTION=sync         # shared hosting has no worker; OTP mail sends inline

# Email OTP — needs a real mailbox. Create one in cPanel → Email Accounts.
MAIL_MAILER=smtp
MAIL_HOST=mail.testcaresortwork.co.in
MAIL_PORT=465
MAIL_ENCRYPTION=ssl
MAIL_USERNAME=no-reply@testcaresortwork.co.in
MAIL_PASSWORD=<mailbox password>
MAIL_FROM_ADDRESS=no-reply@testcaresortwork.co.in
MAIL_FROM_NAME=Grocerly

# Set false if SMTP is not ready yet (sign in with password only):
AUTH_OTP_ENABLED=true

STRIPE_PUBLISHABLE_KEY=pk_test_xxx
STRIPE_SECRET=sk_test_xxx
STRIPE_WEBHOOK_SECRET=whsec_xxx     # from the dashboard endpoint you create in step 8
```

---

## 6. Initialise (cPanel → Terminal, or SSH)

```sh
cd ~/gdp-app
php artisan key:generate
php artisan migrate --force
php artisan db:seed --force        # optional: demo catalog + admin test@example.com
php artisan storage:link           # if it fails, manually symlink public/storage → ../storage/app/public
php artisan config:cache
php artisan route:cache
```

If Terminal is not available, run these via a throwaway route or ask the host to enable SSH.
`key:generate` can also be done locally and the `APP_KEY` pasted into `.env`.

Point `storage:link` at the public folder: the link must be
`public_html/gdp/storage` → `/home/<cpuser>/gdp-app/storage/app/public`.

### Permissions

```sh
chmod -R 775 ~/gdp-app/storage ~/gdp-app/bootstrap/cache
```

---

## 7. Smoke test

- `https://testcaresortwork.co.in/gdp/api/config` → JSON (Stripe key, fees)
- `https://testcaresortwork.co.in/gdp/api/products` → JSON catalog
- `https://testcaresortwork.co.in/gdp/` → the storefront loads, catalog renders
- Register / sign in → OTP email arrives (or set `AUTH_OTP_ENABLED=false` and re‑cache config)
- Admin: sign in as the seeded `test@example.com` / `password`, open **Admin**

If you see a Laravel error page: set `APP_DEBUG=true` temporarily, `php artisan config:clear`,
reload, read the message, then turn it back off and re‑cache.

---

## 8. Stripe webhook

In the Stripe dashboard → Developers → Webhooks, add an endpoint:

```
https://testcaresortwork.co.in/gdp/api/payments/stripe/webhook
events: payment_intent.succeeded, payment_intent.payment_failed, payment_intent.canceled
```

Copy its signing secret into `.env` as `STRIPE_WEBHOOK_SECRET`, then
`php artisan config:cache`.

---

## 9. Redeploying later

```cmd
:: local
cd /d D:\gdp\backend && composer install --no-dev --optimize-autoloader
cd /d D:\gdp\web && npm run build
```

Upload changed files, then on the server:

```sh
cd ~/gdp-app
php artisan migrate --force
php artisan config:cache && php artisan route:cache
```

Re‑upload `web/dist/*` into `public_html/gdp/` (the `assets/` filenames are hashed, so
clear out old ones).

---

## Notes / limits on shared hosting

- `QUEUE_CONNECTION=sync` — no background worker. OTP mail and notifications send during the
  request. Fine for this MVP.
- No Redis — `CACHE_STORE=file`, `SESSION_DRIVER=file`.
- The mobile app (`mobile/`) is not part of this deploy. Point it at the live API by setting
  `EXPO_PUBLIC_API_URL=https://testcaresortwork.co.in/gdp/api` before `expo start`.
- Keep `APP_DEBUG=false` in production. Never upload `.env`, `storage/logs/*`, or `vendor/`
  from another machine's PHP version mismatch — run `composer install` on the target PHP if
  unsure.
