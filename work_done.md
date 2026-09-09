# Grocerly — Access & Menu Guide

---

## Admin access

**URL:** https://testcaresortwork.co.in/gdp/admin
**Username:** test@example.com
**Password:** password

### Admin menus

| Menu | What it does |
| --- | --- |
| **Dashboard** | Business overview — revenue, order and customer counts, discounts, refunds, plus orders-trend, payments-vs-refunds, "when orders come in" and period-comparison charts. |
| **Orders** | View every order (with the store that fulfils it), filter by status, advance the delivery stage, assign a rider, mark cash collected, and issue full/partial Stripe refunds. |
| **Products** | Add, edit and delete products — price, sale price, image, per-item variants (size/weight/flavour), and **per-store stock**: turn on "Track stock per store" for a grid of each store's own count (0 = shown "out of stock", unticked = not carried there). |
| **Categories** | Add, edit, delete and reorder product categories, set their image and active/inactive state. |
| **Customers** | See all customers with order count and spend, open a customer's addresses and order history, and grant the delivery-rider role. |
| **Riders** | Add a rider (by email), set their phone, on/off-shift state, home base (address or map pin) and which stores they serve. Orders are auto-assigned to the nearest on-shift rider linked to the order's store; unassigned ones fall back to the pickup pool. Each rider row shows their ★ rating; **Reviews** opens a panel with lifetime deliveries and every customer rating **including the written comment** — comments are admin-only and never shown to the rider. |
| **Stores** | Manage store/hub locations — address, map coordinates, delivery radius and active state. Stores can be in different cities; a customer inside any store's radius can order, and the nearest covering store serves them. |
| **Store settings** | Set the store name, tagline, logo, favicon, light/dark theme, brand colours and boxed/full page width. |
| **Secure access** | Change the admin email/phone and manage the Stripe API keys, protected by a password re-check. |
| **Pages → Homepage** | Manage the homepage banners (hero and 3-up strip) and the category tiles — images, links, order and visibility. |
| **Pages → Footer** | Edit the footer copyright, disclaimer, App Store / Play Store links, social-media links and custom links. |
| **Pages → All pages** | Create and edit content pages (About, Contact, Privacy, etc.) using text or drag-and-drop section blocks and a header banner image. |
| **Pages → Blogs** | Create and edit blog posts as their own pages, kept in a separate group. |
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

A dashboard strip at the top of the console shows lifetime deliveries, this
week's count with the change vs last week, the ★ rating and the code-verified
share. Scores only — customer comments are never shown to the rider.

When a new order is assigned (by the admin or auto-assign), the rider gets an
email and the console sounds an alarm + shows a banner. The **Alert sound** menu
in the header picks a preset tone (Urgent alarm / Chime / Bell / Siren) or lets
the rider upload their own short clip, with a mute toggle and a Test button. The
mobile app vibrates and shows the same banner.
