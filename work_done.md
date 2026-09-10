# Grocerly — Access & Menu Guide

---

## Recent updates (2026-09)

>> Improved fonts (self-hosted Okra, Blinkit's typeface), fixed footer spacing and hero-banner width, page body text now renders *italic*.

>> Redesigned the admin console — cleaner sage background, bigger fonts, rounder buttons, zebra-striped tables, darker contrast, and strong hover states on every clickable element including dropdowns and file pickers; the selected left-menu item now matches its hover colour; every "Loading…" placeholder shows a rotating spinner.

>> Dashboard polish — moved the Payments-vs-refunds pie beside the period comparison, and animations/spacing across the dashboard charts.

>> Admin fixes — rider "Reviews" opens a reviews-only overview (not the full stats), the Orders "Actions" column never renders blank, the Orders table fits without horizontal scrolling, and the Store-settings Colours section is clearer.

>> Rider delivery offers — an assignment is now a 60-second OFFER the rider must Accept or Reject, with a looping alarm; a reject or timeout re-offers to the next-best rider or drops the order to the shared pickup pool. Admin sees per-order offer status (offered / accepted / declined ×N).

>> Rider parameters & attendance system — rejected / missed counts and acceptance rate on the rider dashboard and admin; clock in / lunch break / clock out; availability hours that gate auto-assignment; rider- or admin-set "unavailable" with a reason note; online-now heartbeat; per-rider monthly attendance report (full / short / off-day classification).

>> Improved page & blog editor — an "upload from computer" button beside every image field (banner, hero, media, feature cards); edit forms scroll into view when opened and close when you switch menu or change a filter; added a **Formatting guide** tab under Pages listing every Markdown element with a live preview.

>> Product search — filter the list by category (alongside name/SKU and store), with the whole filter bar kept on one row.

>> Storefront catalogue — the shop now loads every product, not just the first alphabetical page (items past ~"T", such as Whole Milk, were previously never shown under their category).

---

## Admin access

**URL:** https://testcaresortwork.co.in/gdp/admin
**Username:** test@example.com
**Password:** password

### Admin menus

| Menu | What it does |
| --- | --- |
| **Dashboard** | Business overview — revenue, order and customer counts, discounts, refunds, plus orders-trend, payments-vs-refunds, "when orders come in" and period-comparison charts. |
| **Orders** | View every order (with the store that fulfils it), filter by status, advance the delivery stage, assign a rider, mark cash collected, and issue full/partial Stripe refunds. The Delivery column shows each order's rider-offer state (offered / accepted / declined ×N). |
| **Products** | Add, edit and delete products — price, sale price, image, per-item variants (size/weight/flavour), and **per-store stock**: turn on "Track stock per store" for a grid of each store's own count (0 = shown "out of stock", unticked = not carried there). Search by name/SKU and filter by category and store. |
| **Categories** | Add, edit, delete and reorder product categories, set their image and active/inactive state. |
| **Customers** | See all customers with order count and spend, open a customer's addresses and order history, and grant the delivery-rider role. |
| **Riders** | Add a rider (by email), set their phone, on/off-shift state, home base (address or map pin) and which stores they serve. Orders are auto-assigned to the nearest available on-shift rider linked to the order's store; unassigned ones fall back to the pickup pool. Each row shows the rider's live status (clocked in / on break / off / unavailable), ★ rating, and acceptance / rejected / missed figures. **Reviews** opens a reviews-only panel (score, star breakdown, every customer comment — admin-only); **Attendance & stats** opens the drawer with worked-hours tiles and the monthly attendance report. Force a rider offline with a reason note. |
| **Stores** | Manage store/hub locations — address, map coordinates, delivery radius and active state. Stores can be in different cities; a customer inside any store's radius can order, and the nearest covering store serves them. |
| **Store settings** | Set the store name, tagline, logo, favicon, light/dark theme, brand colours and boxed/full page width. |
| **Secure access** | Change the admin email/phone and manage the Stripe API keys, protected by a password re-check. |
| **Pages → Homepage** | Manage the homepage banners (hero and 3-up strip) and the category tiles — images, links, order and visibility. |
| **Pages → Footer** | Edit the footer copyright, disclaimer, App Store / Play Store links, social-media links and custom links. |
| **Pages → All pages** | Create and edit content pages (About, Contact, Privacy, etc.) using text or drag-and-drop section blocks and a header banner image. |
| **Pages → Blogs** | Create and edit blog posts as their own pages, kept in a separate group. |
| **Pages → Formatting guide** | A reference of every Markdown element the page/blog body supports (headings, bold, italic, code, links, lists, divider), each shown as the code to type next to a live preview. |
| **Support** | Read customer support chats, reply, mark them resolved/reopened, and issue a refund from within a conversation. Each thread shows the customer's ★ chat rating (with their comment) in the list and on the thread drawer. |
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
| **Checkout** | Choose a saved or new delivery address, add a phone number and delivery note, and pick card or cash on delivery. |
| **Payment** | Pay by card (Stripe), use a saved card, or tick "save this card" for next time. |
| **Orders** | Track delivery status, complete payment, cancel an order, download the bill (PDF), or get help on an order. Once an order is delivered, rate the rider 1–5 stars with an optional private note (also available from the delivery chat); the note goes to the Grocerly team only. |
| **Account → Profile** | Update name and phone, and change password. |
| **Account → Addresses** | Add, edit, delete and set a default delivery address. |
| **Account → Payment methods** | Add a card, set a default, and remove saved cards. |
| **Help** | Start a support chat (optionally linked to an order) and message the store. Once the store has replied, rate the conversation 1–5 stars with an optional comment at the end of the chat. |
| **Footer pages** | Read About Us, Blog, Contact, FAQs, Privacy Policy, Terms of Service and Security. |
| **Sign in / Sign up** | Email-code, or email + password (Create an account / Forgot password on the Password tab). |

### Rider console (web) — BASE + /rider

Sign in with a rider account (`rider@example.com` / `password`). Shows the rider's
assigned deliveries (including orders still being packed) and the pickup pool,
refreshed every 15 seconds.

| Action | What it does |
| --- | --- |
| **Start delivery** | Moves a ready order to out-for-delivery. |
| **Deliver** | Confirms the handover: sends a 6-digit code to the customer to read back, or — if that can't be done — marks it delivered with a required note. |
| **Cash collected** | Marks a cash-on-delivery order paid. |
| **Pick up** | Claims an unassigned order from the pool. |
| **Directions** | Opens the delivery address in Google Maps. |
| **Message customer** | Chat with the customer for that order (shows up in their Help inbox and the admin Support tab). |
| **Clock in / Lunch break / Clock out** | Track availability hours. Auto-assignment only offers orders while the rider is clocked in and not on break; the rider (or an admin) can also go "unavailable" with a reason note. |

A dashboard strip at the top of the console shows lifetime deliveries, this
week's count with the change vs last week, the ★ rating and the code-verified
share, plus **rejected / missed** counts and **acceptance rate**. Scores only —
customer comments are never shown to the rider.

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
