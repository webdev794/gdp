# Tudee Shopping Center — Access & Menu Guide

---

## Admin access

**URL:** https://testcaresortwork.co.in/gdp/admin
**Username:** test@example.com
**Password:** password

### Admin menus

| Menu | What it does |
| --- | --- |
| **Dashboard** | Business overview — revenue, order and customer counts, discounts, refunds, plus orders-trend, payments-vs-refunds, "when orders come in" and period-comparison charts. All charts bucket by the admin's own local time (auto-detected from the browser), not the server's clock. The orders-trend chart (Daily / Weekly / Monthly / **Yearly** = last 12 years) shows the total amount of orders placed, revenue earned and refunds on one shared **dollar scale** with $ marks on the side — hover a dot for the amount and how many orders it covers. "Orders by payment" counts delivered orders. "When orders come in" can be viewed by **month and year** (a row per day) or the last 90 days by weekday; each square is split red (share cancelled) / green. The 🔔 **notification bell** (top bar) lists new orders awaiting packing, customers who refused cash-on-delivery, riders sitting on unreturned cash, recent negative feedback, and recent refunds/gift cards issued — each dismissible with its own ✕, with a badge count and a one-time ring when something new arrives. A separate 🔊 **speaker** menu lists new orders and new chat messages needing a reply, and holds the on/off switch for **all admin sounds**. Any customer rating (good or bad) also pops a brief toast that fades on its own. The top bar shows the store logo (click it for the Dashboard), an **open orders** counter and **Log out**; a footer shows the store name and a View store link. Menus with a submenu close on a second click. |
| **Orders** | View every order (with the store that fulfils it), filter by status, advance the delivery stage, assign a rider, mark cash collected, and issue full/partial Stripe refunds or store-credit gift cards (once only per order, capped at what's left to refund, redeemable only by that order's own customer). Refunds and gift cards show who issued them and why, both in the order drawer and in the Orders table. The Delivery column shows each order's rider-offer state (offered / accepted / declined ×N) and is colour-coded when the order carries negative customer feedback. Click an order number for a summary drawer (items, fee breakdown, delivery address, courier — locked once the order is delivered or cancelled); a card order whose payment was abandoned can be Cancelled. If a rider reports the customer refused to pay for a cash-on-delivery order, it's auto-cancelled and flagged for the admin to confirm once the bagged items are physically back at the store. Cancelling an order automatically refunds any gift card spent on it. The customer is emailed an order summary with the PDF bill attached once an order is paid and delivered. A sound + on-screen alert fires for every new order that's ready to be packed. Two customers sharing the same name are told apart everywhere with a "[1]" / "[2]" suffix. **Cancelling needs a reason** (shown to the customer as "Cancelled (reason)"); **completing needs a rider/courier or "Customer picked up"**. |
| **Products** | Add, edit and delete products — price, sale price, primary image, an **image gallery** (extra photos shown alongside the primary image in the storefront's product gallery), per-item variants (size/weight/flavour, each with its own optional image), and **per-store stock**: turn on "Track stock per store" for a grid of each store's own count (0 = shown "out of stock", unticked = not carried there). Each product is **Live, Demo or Draft** (WordPress-style All / Live / Demo / Draft links with counts); submenu **All products / Add new product**. Search by name/SKU and filter by category and store. **Demo products** (the seeded sample catalogue) can be hidden, shown or deleted in bulk — hidden products disappear from the website and the mobile apps. |
| **Categories** | Add, edit and delete product categories, upload each one's image and set active/inactive. **Drag and drop** to reorder, or type a sort number — numbers always stay 1, 2, 3… with no duplicates. The homepage category tiles follow this list (order, image, on/off). |
| **Reviews** | Every product review customers wrote (stars, comment, product, customer). New reviews wait for **Approve** (shown in the 🔔 bell) before they appear on the website and apps. **Hide/Show** takes a review off the website and apps and out of the average; **Delete** removes it (for abusive or wrong reviews). |
| **Customers** | See all customers with order count and spend, open a customer's addresses and order history, and grant the delivery-rider role. Riders/admins carry a small **Rider** / **Admin** tag after their name. |
| **Riders** | Add a rider (by email) — a store must be assigned at hire time so it's always clear where their cash gets returned — and set their phone, on/off-shift state, home base (address or map pin) and which stores they serve. Orders are auto-assigned to the nearest available on-shift rider linked to the order's store; unassigned ones fall back to the pickup pool. Each row shows the rider's live status (clocked in / on break / off / unavailable), current location, ★ rating, acceptance / rejected / missed figures, and any cash-on-delivery money they're still holding (amber if from today, red once it's carried over a day) with a **Confirm cash returned** button. **Reviews** opens a reviews-only panel (score, star breakdown, every customer comment — admin-only); **Attendance & stats** opens the drawer with worked-hours tiles and the monthly attendance report. Force a rider offline with a reason note. |
| **Stores** | Manage store/hub locations — address, map coordinates, delivery radius and active state. Stores can be in different cities; a customer inside any store's radius can order, and the nearest covering store serves them. |
| **Store settings** | Set the store name, tagline, logo, favicon, light/dark theme, brand colours and boxed/full page width, plus the contact email, phone and address that pages fill in automatically (`{email}`, `{phone}`). The store name here is used everywhere (website, apps, emails). Submenu: **Footer**. |
| **Secure access** | Change the admin email/phone and manage the Stripe API keys, protected by a password re-check. |
| **Pages → All pages** (Homepage row) | Manage the homepage banners (hero and 3-up strip). Category tiles are managed under **Categories**. |
| **Store settings → Footer** | Edit the footer copyright, disclaimer, App Store / Play Store links, social-media links and custom links. |
| **Pages → All pages / Add new page** | Create and edit content pages (About, Contact, Privacy, etc.) using text or drag-and-drop section blocks and a header banner image. |
| **Blogs** (own menu) | **All blogs** lists only blog posts; **Add new blog**; the Formatting guide is linked here too. |
| **Pages → Formatting guide** | A reference of every Markdown element the page/blog body supports (headings, bold, italic, code, links, lists, divider), each shown as the code to type next to a live preview. |
| **Support** | Read customer support chats, reply, mark them resolved/reopened, and issue a full/partial refund from within a conversation. Customers can **attach a photo** (e.g. a damaged product) when opening a request or replying; it shows inline in the thread for both the customer and admin. For an order with no card payment to reverse (e.g. cash on delivery), issue **store credit** instead — pick the missing item(s) or an amount and a gift-card code + password are generated and posted straight into the chat for the customer to use on a future order. If the customer already has store credit from an earlier order, it can be applied straight to a different order of theirs that's still unpaid, right from the chat. A reason typed in for a refund or gift card is saved as an internal note in the same thread — kept for admin reference only, never shown to the customer. A sound + toast alerts the admin to every new message. Each thread shows the customer's ★ chat rating (with their comment) in the list and on the thread drawer. |
| **Settings** | Configure checkout charges — tax rate, delivery fee, handling fee, small-cart surcharge — turn cash-on-delivery on/off, and turn rider auto-assignment on/off. |

---

## Client access

**URL:** https://testcaresortwork.co.in/gdp/
**Username:** testcaresort@outlook.com
**Password:** password

### Client menus

| Menu | What a client can do |
| --- | --- |
| **Search bar** | Type to find any product by name. |
| **Set your location** | Drop a map pin, detect location or search an address to check delivery and get an ETA. |
| **Categories** | Browse products by category from the tiles or the top rail. |
| **Product / Add** | Pick a variant, see regular vs sale price, and add items to the cart. |
| **Cart / View cart** | Change quantities, remove items, and see the running subtotal, fees, tax and total. |
| **Checkout** | Choose a saved or new delivery address, add a phone number and delivery note, pick card or cash on delivery, and — if support has issued one — enter a gift-card code + password to apply store credit (checked before you pay: it shows how much will be used for this order and how much stays on the card for the next one; the placed order shows "Gift card applied" and the balance left). |
| **Payment** | Pay by card (Stripe), use a saved card, or tick "save this card" for next time. |
| **Orders** | Track delivery status, complete payment, cancel an order, download the bill (PDF), or get help on an order. Once an order is delivered, rate the rider 1–5 stars with an optional private note (also available from the delivery chat); the note goes to the store team only. Each item on a confirmed order can be **rated once per order** (1–5 stars + a few words); ratings show on the product page. When the rider asks for the **delivery code**, it pops up on whatever page is open (plus a browser notification if allowed) and is also emailed. |
| **Account → Profile** | Update name and phone, and change password. |
| **Account → Addresses** | Add, edit, delete and set a default delivery address. |
| **Account → Payment methods** | Add a card, set a default, and remove saved cards. |
| **Help** | Start a support chat (optionally linked to an order), message the store, and attach a photo to a message (e.g. to show a damaged item). Once the store has replied, rate the conversation 1–5 stars with an optional comment at the end of the chat. **End Chat** closes it (replying reopens it). |
| **Footer pages** | Read About Us, Blog, Contact, FAQs, Privacy Policy, Terms of Service and Security. |
| **Sign in / Sign up** | Email-code, or email + password (Create an account / Forgot password on the Password tab). |

### Rider console (web) — BASE + /rider

Sign in with a rider account (`rider@example.com` / `password`). Shows the rider's
assigned deliveries (including orders still being packed) and the pickup pool,
refreshed every 15 seconds.

| Action | What it does |
| --- | --- |
| **Start delivery** | Moves a ready order to out-for-delivery. |
| **Deliver** | Confirms the handover: sends a 6-digit code to the customer to read back (emailed and popped up in their app/website; **Resend a new code** as often as needed, each valid 15 min), or — if that can't be done — marks it delivered with a required note. On a cash-on-delivery order this is only available after **Cash collected** is used. |
| **Cash collected** | Marks a cash-on-delivery order paid — required before that order can be marked delivered. |
| **Customer refused to pay** | Cancels a cash-on-delivery order on the spot when the customer won't pay, with a required note for the store. |
| **Pick up** | Claims an unassigned order from the pool. |
| **Directions** | Opens the delivery address in Google Maps. |
| **Message customer** | Chat with the customer for that order (shows up in their Help inbox and the admin Support tab). |
| **Clock in / Lunch break / Clock out** | Track availability hours. Auto-assignment only offers orders while the rider is clocked in and not on break; the rider (or an admin) can also go "unavailable" with a reason note. |

A dashboard strip at the top of the console shows lifetime deliveries, this
week's count with the change vs last week, the ★ rating and the code-verified
share, cash currently held from cash-on-delivery drop-offs, plus
**rejected / missed** counts and **acceptance rate**. Scores only — customer
comments are never shown to the rider. If a customer refused to pay and the
rider is still holding those bagged items, a standing reminder shows on the
dashboard until the store confirms they're back.

**Delivery offers.** When an order is assigned (by the admin or auto-assign) the
rider gets a full-screen **60-second offer** they must **Accept** or **Reject**,
with a looping alarm and an email. A reject — or letting the timer run out —
re-offers the order to the next-best rider, and if none is eligible it drops to
the shared pickup pool. The admin's Orders list shows each order's offer state
(offered to X / accepted / declined ×N). The **Alert sound** menu in the header
picks a preset tone (Urgent alarm / Chime / Bell / Siren) or lets the rider
upload their own short clip, with a mute toggle and a Test button. The mobile app
vibrates and shows the same prompt.

A per-rider **monthly attendance report** (reachable from the admin rider drawer)
classifies each day as a full day, short day or day off from the clock-in ledger,
with hours worked and averages.

---

## Mobile apps — Android & iPhone (`flutter_app/`)

One Flutter app for both phones, **Tudee Shopping Center**, for customers. It uses the same store API as the website, so the account, orders, cards, addresses, chats, gift cards and reviews are the same on phone and website — anything done in one shows in the other.

**Sign in:** same accounts as the website (email + password, or email code).

| Screen | What a customer can do |
| --- | --- |
| **Home** | Browse the store's categories and products (only what Admin publishes, with the store's images), search, see stock ("OUT OF STOCK" when sold out), set the delivery address. |
| **Product** | Photos, price/sale price, variants, description, availability, and customer reviews with the average rating. |
| **Cart & checkout** | Delivery address (saved addresses from the account, or pick on the map), phone, delivery note, and the same fees/tax as the website. Pay with a **saved card**, a **new card** (name, number, expiry, CVC; optionally saved for next time) or **cash on delivery**. Gift card: shows how much is used and how much stays on the card. |
| **My Orders** | Every order from the app and the website, live status (confirmed → packing → out for delivery → delivered), download the bill (PDF), rate each item once per order, rate the rider after delivery (comment goes to the store only). The **delivery code pops up** when the rider asks for it. |
| **Support** | Same chats as the website: start a chat (optionally about an order), get staff replies, **End chat**, rate the chat — or rate the rider for chats the rider started. |
| **Account** | Profile, saved addresses, **Payments** (add / set default / remove cards). |

**Getting the apps**

- **Android:** after the live site is updated, open `https://testcaresortwork.co.in/gdp/downloads/tudee-shopping-center.apk` on the phone and install it (Android asks once to allow installs from the browser). Also runs on Appetize.
- **iPhone:** built on GitHub's Mac machines — GitHub → Actions → **Flutter iOS build** → Artifacts. `TudeeShoppingCenter-iOS-simulator` runs on Appetize (iOS) for testing in any browser. Installing on real iPhones (TestFlight / App Store) needs the client's Apple Developer account.
- **Website address:** the app talks to `https://testcaresortwork.co.in/gdp`; for the client's own domain it is changed in one place (`flutter_app/lib/config.dart`, or `--dart-define=SITE_URL=…` when building).
