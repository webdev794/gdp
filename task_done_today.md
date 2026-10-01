# Tasks done today — 1 Oct 2026

## Admin — orders

- **Customer picked up** option in the rider dropdown closes an order without a courier; **open orders** counter in the top bar.
- **Cancelling needs a reason** (dropdown appears after Cancel). Customers see "Cancelled (reason)" on the website and app; "Customer requested" shows to them as "Contact support if this wasn't expected". The reason also shows in the admin Delivery column.
- **Completing an order needs a rider/courier or "Customer picked up"** (not needed for cancelling).

## Admin — products, categories, reviews, customers

- Products are **Live / Demo / Draft** (status at the top right of the form, one Status column, WordPress-style All / Live / Demo / Draft links with counts). Products submenu **All products / Add new product**; list, search and demo box hide while editing.
- **Categories:** drag and drop to reorder; a typed sort number inserts at that place and everything is renumbered 1, 2, 3… (no duplicates, also after delete). Each category now has its own **image upload**; the homepage category tiles follow the Categories list (tiles editor removed from Pages → Homepage, old tile images copied over).
- **Reviews need admin approval:** new reviews are pending, shown in the 🔔 bell, and go live after **Approve**. Reviews sit in a proper box in the product pop-up.
- **Customers:** small **Rider** / **Admin** tag after the name.

## Admin — menus and layout

- **Pages:** click opens All pages; submenu All pages / Add new page / Formatting guide; Homepage is a row in All pages; blog posts no longer mixed in.
- **Blogs** is its own menu: All blogs / Add new blog / Formatting guide; list hidden while editing.
- **Footer** editor moved under **Store settings**.
- Second click on a menu closes its submenu.
- Top bar: **store logo** from Store settings (click → Dashboard), **Log out** button; "Back to store" removed. New black **footer** with the store name and View store link.
- The 🔊 switch now turns **all admin sounds** on/off.

## Admin — dashboard charts

- **Orders trend:** Orders (total amount of orders placed), Revenue and Refunds selected by default, all on one **dollar scale** with $ marks; new **Yearly** view (last 12 years); hovering a dot shows the amount and how many orders.
- **Orders by payment** counts delivered orders only.
- **When orders come in:** pick **month and year** (a row per day, 28–31) or the last 90 days by weekday; each square is split **red (cancelled share) / green**.

## Other

- Store name has one source (Admin → Store settings) for website, apps and emails.
- Fixed a rider attendance test that failed on the 1st of each month.
- All 415 backend tests pass; docs updated; branch `TSC_v15` pushed.

Open items: see `PENDING_TASKS.md`.
