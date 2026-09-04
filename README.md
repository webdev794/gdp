# GDP Grocery Delivery Platform

## See Output Quickly

Open Windows Command Prompt and run:

```cmd
cd /d D:\gdp\backend
"D:\xampp8-2-12\php84\php.exe" -d display_errors=0 artisan serve
```

Open the application in a browser:

- Website: <http://127.0.0.1:8000>
- Designed React storefront: <http://127.0.0.1:5173>
- API user endpoint: <http://127.0.0.1:8000/api/user>
- API categories endpoint: <http://127.0.0.1:8000/api/categories>
- API products endpoint: <http://127.0.0.1:8000/api/products>
- API orders endpoint (requires a bearer token): <http://127.0.0.1:8000/api/orders>
- API admin orders endpoint (requires an admin bearer token): <http://127.0.0.1:8000/api/admin/orders>
- API public client config (Stripe publishable key, checkout fees): <http://127.0.0.1:8000/api/config>

To start the designed React storefront, open another Command Prompt window and run:

```cmd
cd /d D:\gdp\web
npm.cmd run dev -- --host 127.0.0.1 --port 5173
```

Then open <http://127.0.0.1:5173>.

Keep both servers running together. The React storefront uses the Laravel API on port `8000` for catalog, authentication, cart synchronization, and checkout.

To see catalog JSON output from Command Prompt while the server is running:

```cmd
curl http://127.0.0.1:8000/api/categories
curl http://127.0.0.1:8000/api/products
```

Press `Ctrl+C` in the server terminal to stop Laravel.

USA online grocery delivery MVP with a Blinkit-style customer ordering journey. The initial market is the United States and the currency is USD.

The project is designed around one Laravel API that will serve the customer website, admin panel, and future Android and iOS applications.

## Product Goal

Build a simple, professional, reliable grocery delivery MVP that can be tested with real US customers and expanded in future versions. The objective is not to build a full Blinkit clone.

## Technology Plan

- Laravel API backend
- PHP 8.4
- MySQL
- Redis for cache, queues, and scalable application services
- Laravel Sanctum for API authentication
- Stripe for payments
- React customer website using the Laravel API
- React Native Android and iOS applications using the same Laravel API
- Cloud-storage-compatible product media storage
- Queues, notifications, logging, validation, and automated tests

## Development Rules

- Backend architecture, database schema, API contracts, authentication, and order/payment boundaries come before client UI.
- All important business logic remains on the Laravel backend.
- The server controls product prices, inventory, order totals, tax, delivery fees, payment status, and order status.
- Stripe webhook confirmation is the authoritative payment confirmation mechanism.
- Payment webhooks must verify signatures and handle successful, failed, cancelled, duplicate, and out-of-order events safely.
- The React website and React Native applications use the same versioned API contracts.
- Customer and administrator authorization is explicit and deny-by-default.
- The MVP prioritizes a complete and reliable customer ordering journey over speculative features.

## Customer Website Requirements

- Registration and login
- Homepage
- Categories
- Product listing and product details
- Product search
- Cart
- Checkout
- Address management
- Stripe payment
- Order confirmation
- Order history
- Order status tracking
- Customer support and live chat

## Mobile Application Requirements

Android and iOS applications must provide the same essential customer shopping and ordering functionality:

- Registration and login
- Product and category browsing
- Search
- Product details
- Cart
- Checkout
- Stripe payment
- Orders and order tracking
- Profile and address management
- Customer support and live chat

The mobile clients will use the Laravel API. They must not duplicate pricing, totals, payment, inventory, or order-state business logic.

## Admin Panel Requirements

Administrators must be able to manage:

- [x] Dashboard
- [x] Products
- [x] Categories
- [x] Customers
- [x] Orders
- [x] Payment status
- [x] Delivery assignment (free-text courier on the order)
- [x] Delivery and order status
- [ ] Customer support conversations (see priority 11)

## Backend Requirements

- Laravel API
- MySQL database
- Redis cache and queue support
- Authentication and authorization
- Product, category, customer, address, cart, order, and payment domains
- Stripe payment processing and secure Stripe webhooks
- Queued jobs and notifications
- Structured validation and API error responses
- Application logging and security controls
- Cloud-storage-compatible media handling
- Automated feature and unit tests

## Development Status

### Completed

- [x] Laravel 13 API project created in `backend/`
- [x] PHP 8.4 verified and used for Laravel commands
- [x] Composer dependencies installed
- [x] MySQL database `gdp` configured and migrations executed
- [x] Laravel application key generated
- [x] Laravel Sanctum installed
- [x] Sanctum token migration published and executed
- [x] Sanctum `HasApiTokens` added to the User model
- [x] API route scaffolding created
- [x] Customer registration endpoint
- [x] Customer login endpoint
- [x] Customer logout endpoint with token revocation
- [x] Protected current-user endpoint
- [x] Authentication feature tests
- [x] Product and category database schema
- [x] Public category and product API endpoints
- [x] Active catalog visibility and category filtering
- [x] Server-side product search by name, description, and SKU
- [x] Catalog feature tests
- [x] Repeatable demo grocery catalog seed data
- [x] JSON response for unauthenticated API requests
- [x] Authenticated server-side cart with inventory validation
- [x] Cart feature tests
- [x] Server-calculated checkout orders with tax and delivery fees
- [x] Checkout inventory validation and order snapshot tests
- [x] Responsive React customer storefront
- [x] Storefront catalog loading, search, category filters, and cart preview
- [x] Interactive cart drawer with quantity controls
- [x] Sign in and registration forms connected to Laravel API
- [x] Checkout address form and pending-payment order confirmation
- [x] Saved customer address database and protected address APIs
- [x] Checkout support for saved address IDs
- [x] Storefront address saving and saved-address checkout selection
- [x] Optional address capture during customer registration
- [x] Registration address saved as the customer default address
- [x] Stripe PaymentIntent and signed webhook backend boundary
- [x] Stripe card payment screen connected to PaymentIntent flow
- [x] PaymentIntent reused on retry instead of creating duplicates
- [x] Idempotent Stripe webhook that records processed event ids
- [x] Guarded payment lifecycle for successful, failed, cancelled, duplicate, and out-of-order events
- [x] Stripe webhook feature tests covering every transition
- [x] Customer order history and order detail API endpoints
- [x] Storefront order history view with payment status badges
- [x] Resume payment for an unpaid order from order history
- [x] Server reconciles an order from Stripe when the webhook is missed or delayed
- [x] Checkout address modal dismissed when payment begins
- [x] Admin role flag on users, denied by default and never mass-assignable
- [x] Deny-by-default `admin` middleware guarding the admin API
- [x] Server-side order delivery state machine with guarded transitions
- [x] Admin order list, filter, detail, and status-advance endpoints
- [x] Storefront delivery progress tracker in order history
- [x] Delivery workflow feature tests
- [x] Admin dashboard metrics and customer list endpoints
- [x] Admin console in the storefront: dashboard, orders, products, categories, customers
- [x] Order status advancing, cancellation, and courier assignment from the admin order table
- [x] Admin product create, edit, delete with slug generation and order-safety guard
- [x] Admin category create, edit, delete with in-use guard
- [x] Admin customer detail with address and order history
- [x] Admin dashboard, product, and category feature tests
- [x] Email OTP step on register and login, with resend cooldown and attempt lockout
- [x] Storefront OTP entry screen with resend
- [x] Throttled auth routes and OTP feature tests
- [x] Public `GET /api/config` for client Stripe key and checkout fees
- [x] Expo (React Native) Android customer app scaffolded in `mobile/`
- [x] Mobile: OTP auth, catalog, search, product detail, cart, checkout, order tracking
- [x] Mobile: in-app Stripe card payment via a WebView on the PaymentIntent flow
- [x] Grocerly browser page metadata and local Vite development server
- [x] Public storage symlink created
- [x] Initial test suite passing
- [x] Initial project backup pushed to `webdev794/gdp`

### Pending Development Priorities

1. [x] Authentication
2. [x] Products and categories
3. [x] Search
4. [x] Cart
5. [x] Checkout
6. [x] Stripe payment and webhook processing
7. [x] Order management
8. [x] Delivery workflow
9. [x] Admin panel
10. [ ] Mobile applications for Android and iOS
    - [x] Android customer app (Expo): auth + OTP, catalog, cart, checkout, Stripe payment, order tracking
    - [ ] Push notifications
    - [ ] In-app customer support (depends on priority 11)
    - [ ] iOS pass: same Expo codebase, needs a Mac / EAS build and testing
    - [ ] Standalone build config (`expo-build-properties` for cleartext, app icons, EAS)
11. [ ] Live chat and customer support
12. [ ] Testing and deployment hardening

### Known Gaps To Revisit

- Support-conversation management is not in the admin panel yet; it is tracked with priority 11 (Live chat and customer support).
- `PaymentController::intent()` reconciliation from the live Stripe API is verified manually but not covered by an automated test (needs a Stripe client fake).
- Courier assignment is a free-text `courier_name` on the order. A delivery-partner directory with real assignment is future work.
- The React app has no router; the admin console is a full-screen overlay shown to `is_admin` users. Revisit if the panel grows.
- Product and category images are stored as `image_url` only; no upload UI yet.
- The mobile app confirms card payments in a WebView (Stripe Elements). A native
  `@stripe/stripe-react-native` PaymentSheet would need an Expo dev/EAS build and is a later option.
- `mobile/` has no app icon or splash image assets yet; Expo uses defaults.

## Delivery Workflow

The administrator must be able to move an order through controlled server-side states:

1. Confirmed
2. Preparing
3. Out for delivery
4. Completed

The design must also support cancellation and payment failure without incorrectly marking an order as paid or completed.

### How it works

An order becomes `confirmed` only when Stripe confirms payment. From there an administrator advances it one step at a time:

`confirmed → preparing → out_for_delivery → completed`

Rules enforced server-side by `Order::canTransitionTo()` and `EnsureUserIsAdmin`:

- Only a user with `is_admin = true` may call the admin endpoints; everyone else gets `403`.
- Steps cannot be skipped and `completed` / `cancelled` are terminal.
- An order that is not `paid` cannot move into the delivery states.
- An administrator may cancel an order that is `confirmed` or `preparing`.
- Payment failure and cancellation never set `paid` or `completed`.

Admin endpoints (bearer token belonging to an admin user):

```text
GET    /api/admin/metrics              dashboard counts, paid revenue, low stock
GET    /api/admin/customers            customers with order count and paid spend
GET    /api/admin/customers/{user}     customer detail: addresses and order history
GET    /api/admin/orders               list every order, newest first, optional ?status=
GET    /api/admin/orders/{order}       order detail with items and customer
PATCH  /api/admin/orders/{order}       body: {"status":"preparing"} and/or {"courier_name":"Sam Rider"}
GET    /api/admin/products             all products incl. inactive, optional ?search=
POST   /api/admin/products             create; slug is generated from name when omitted
PATCH  /api/admin/products/{product}   partial update
DELETE /api/admin/products/{product}   409 if the product is on an existing order (deactivate instead)
GET    /api/admin/categories           all categories with product counts
POST   /api/admin/categories           create; slug generated when omitted
PATCH  /api/admin/categories/{category}   partial update
DELETE /api/admin/categories/{category}   409 while the category still has products
```

In the storefront, an `is_admin` account sees an **Admin** link in the header that opens a
full-screen console with tabs for the dashboard, orders (status controls + courier field),
products, categories, and customers (with a per-customer order drawer).

Customer support conversations are part of the admin panel requirements but are being built
under priority 11.

Grant admin rights to an existing account:

```cmd
"D:\xampp8-2-12\php84\php.exe" artisan tinker --execute="App\Models\User::where('email','test@example.com')->update(['is_admin'=>true]);"
```

The database seeder already flags `test@example.com` as an administrator.

## Authentication

Registration and login are email plus password, followed by a one-time code emailed to the
address. The code is 6 digits, expires in 10 minutes, allows 5 attempts, and cannot be
re-sent within 60 seconds.

- `POST /api/auth/register` and `POST /api/auth/login` return `202`/`200` with
  `{"requires_otp": true, "purpose": "...", "email": "..."}` and no token.
- `POST /api/auth/verify-otp` with `{"email", "purpose", "code"}` returns `{"user", "token"}`.
- `POST /api/auth/resend-otp` with `{"email", "purpose"}` sends a fresh code.
- All four routes are rate limited to 12 requests per minute per IP.

Local development: `MAIL_MAILER=log`, so the email is written to
`backend/storage/logs/laravel.log`. With `APP_DEBUG=true` the code is also logged on its own
line as `OTP for <email> (<purpose>): <code>`. Watch it live with:

```cmd
"D:\xampp8-2-12\php84\php.exe" artisan pail
```

To sign in with password only (no code), set `AUTH_OTP_ENABLED=false` in `backend/.env` and
run `php artisan config:clear`.

## Local Backend Setup

From Windows Command Prompt:

```cmd
set "TMP=D:\gdp\.tmp"
set "TEMP=D:\gdp\.tmp"
cd /d D:\gdp\backend

"D:\xampp8-2-12\php84\php.exe" artisan migrate
"D:\xampp8-2-12\php84\php.exe" artisan storage:link
"D:\xampp8-2-12\php84\php.exe" -d display_errors=0 artisan serve
```

The local API is available at `http://127.0.0.1:8000`.

For frontend commands, use the D-drive npm cache:

```cmd
cd /d D:\gdp\web
npm.cmd --cache D:\gdp\.tmp\npm-cache install
npm.cmd --cache D:\gdp\.tmp\npm-cache run dev -- --host 127.0.0.1 --port 5173
```

All temporary project output should go under `D:\gdp\.tmp`. Do not use the nearly-full `C:` drive for project caches or temporary output.

To enable Stripe test payments, add these values to `backend/.env`:

```env
STRIPE_SECRET=sk_test_your_secret_key
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret
```

The webhook secret is not created by the application. Generate it with Stripe CLI while Laravel is running:

```cmd
stripe login
stripe listen --events payment_intent.succeeded,payment_intent.payment_failed,payment_intent.canceled --forward-to http://127.0.0.1:8000/api/payments/stripe/webhook
```

Copy the displayed `whsec_...` value into `STRIPE_WEBHOOK_SECRET`.

On Windows, verify the CLI first:

```cmd
stripe version
```

The CLI is installed for this workstation under the D-drive temporary tools folder. In a new Command Prompt, run:

```cmd
set "PATH=D:\gdp\.tmp\npm-global;%PATH%"
stripe version
stripe login
stripe listen --events payment_intent.succeeded,payment_intent.payment_failed,payment_intent.canceled --forward-to http://127.0.0.1:8000/api/payments/stripe/webhook
```

The listener prints the webhook signing secret. Copy its `whsec_...` value into `backend/.env` as `STRIPE_WEBHOOK_SECRET`. The CLI listener must stay running in its own terminal while testing payments. If you prefer another installation method, use <https://docs.stripe.com/stripe-cli>.

Create `web/.env.local` with the publishable key:

```env
VITE_STRIPE_PUBLISHABLE_KEY=pk_test_your_publishable_key
```

Never commit either environment file or any Stripe secret.

Run tests with:

```cmd
set "TMP=D:\gdp\.tmp"
set "TEMP=D:\gdp\.tmp"
"D:\xampp8-2-12\php84\php.exe" artisan test
```

Never commit `.env`, Stripe keys, database passwords, customer data, `vendor/`, `node_modules/`, logs, or generated local files.

## Repository Layout

```text
gdp/
├── .github/agents/       Custom development agent
├── backend/              Laravel API
├── web/                  React customer website (Vite)
└── mobile/               React Native customer app (Expo) — Android first
```

See `mobile/README.md` for how to run the app in Expo Go and point it at the API.

## Backup Repository

GitHub repository: <https://github.com/webdev794/gdp>
