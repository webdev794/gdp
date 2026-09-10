import { useCallback, useEffect, useRef, useState } from 'react'
import MapPicker from './MapPicker'
import { Delta, Heatmap, LineChart, PieChart } from './Charts'
import { renderMarkdown } from './markdown'
import { SECTION_TYPES, blankSection } from './pageSectionTypes'
import { mediaUrl } from './mediaUrl'
import './Admin.css'

const API_URL = import.meta.env.VITE_API_URL ?? 'http://127.0.0.1:8000/api'

const money = (cents) => `$${((cents ?? 0) / 100).toFixed(2)}`

const STATUS_LABELS = {
  pending_payment: 'Awaiting payment',
  confirmed: 'Confirmed',
  packing: 'Packing',
  ready_for_delivery: 'Ready for delivery',
  out_for_delivery: 'Out for delivery',
  completed: 'Delivered',
  cancelled: 'Cancelled',
}

const NEXT_ACTIONS = {
  confirmed: [['packing', 'Start packing'], ['cancelled', 'Cancel']],
  packing: [['ready_for_delivery', 'Mark ready for delivery'], ['cancelled', 'Cancel']],
  ready_for_delivery: [['out_for_delivery', 'Send out for delivery'], ['cancelled', 'Cancel']],
  out_for_delivery: [['completed', 'Mark delivered']],
  completed: [],
  cancelled: [],
}

const STATUS_FILTERS = ['all', 'confirmed', 'packing', 'ready_for_delivery', 'out_for_delivery', 'completed', 'cancelled']
const PAGE_SIZES = [10, 20, 50, 100, 500, 1000]

// Rows-per-page + page nav shown under a list. `total`/`pageCount` come from the
// server for big lists, or from the array length for small ones paged client-side.
function Pager({ page, pageCount, total, onPage, pageSize, onPageSize }) {
  return (
    <div className="admin-pager">
      <label>Show
        <select value={pageSize} onChange={(event) => onPageSize(Number(event.target.value))}>
          {PAGE_SIZES.map((n) => <option key={n} value={n}>{n}</option>)}
        </select>
        per page
      </label>
      {pageCount > 1 && (
        <span className="admin-pager-nav">
          <button type="button" className="act ghost" disabled={page <= 1} onClick={() => onPage(page - 1)}>‹ Prev</button>
          <span>Page {page} of {pageCount}</span>
          <button type="button" className="act ghost" disabled={page >= pageCount} onClick={() => onPage(page + 1)}>Next ›</button>
        </span>
      )}
      <span className="muted">{total} total</span>
    </div>
  )
}
// Left sidebar vs top-right. Support/Settings stay top-right (used less often,
// and Support carries the live badge next to the notification bell).
const PRIMARY_TABS = ['dashboard', 'orders', 'products', 'categories', 'customers', 'riders', 'stores', 'branding', 'secure']
const TOP_TABS = ['support', 'settings']
const TAB_LABELS = {
  dashboard: 'Dashboard', orders: 'Orders', products: 'Products', categories: 'Categories',
  customers: 'Customers', riders: 'Riders', stores: 'Stores', branding: 'Store settings', secure: 'Secure access',
  homepage: 'Homepage', support: 'Support', settings: 'Settings',
}
const TAB_ICONS = {
  dashboard: '\u{1F4CA}', orders: '\u{1F9FE}', products: '\u{1F4E6}', categories: '\u{1F5C2}️',
  customers: '\u{1F465}', riders: '\u{1F6F5}', stores: '\u{1F3EC}', branding: '\u{1F3A8}', secure: '\u{1F510}',
  homepage: '\u{1F5BC}️',
}
const EMPTY_BRANDING = { store_name: '', tagline: '', logo_url: '', favicon_url: '', theme: 'light', layout_width: 'boxed', color_brand: '#1f7a3d', color_accent: '#ffd23f', color_heading: '#18211c' }
const SOCIAL_PLATFORMS = [['facebook', 'Facebook'], ['x', 'X / Twitter'], ['instagram', 'Instagram'], ['linkedin', 'LinkedIn'], ['youtube', 'YouTube']]
const EMPTY_FOOTER = { copyright: '© {year} Grocerly', note: '', app_store_url: '', play_store_url: '', socials: { facebook: '', x: '', instagram: '', linkedin: '', youtube: '' }, links: [] }

const ISSUE_LABELS = {
  item_missing: 'Item missing', item_damaged: 'Item damaged', wrong_item: 'Wrong item',
  not_delivered: 'Not delivered', payment_issue: 'Payment issue', other: 'Other',
  delivery: 'Delivery message',
}

const EMPTY_PRODUCT = { category_id: '', name: '', sku: '', price: '', compare_at: '', inventory_quantity: 0, description: '', image_url: '', is_active: true, per_store_stock: false, store_stock: {}, variants: [] }

// Build the per-store stock grid ({ [storeId]: { is_stocked, base, variants: { [variantIndex]: qty } } })
// from a product's store_inventory rows.
const storeStockFrom = (product) => {
  const idxById = new Map((product.variants ?? []).map((v, i) => [v.id, i]))
  const map = {}
  for (const row of (product.store_inventory ?? [])) {
    const s = (map[row.store_id] = map[row.store_id] ?? { is_stocked: true, base: '', variants: {} })
    if (row.product_variant_id == null) {
      s.base = String(row.quantity)
      s.is_stocked = !!row.is_stocked
    } else if (idxById.has(row.product_variant_id)) {
      s.variants[idxById.get(row.product_variant_id)] = String(row.quantity)
    }
  }
  return map
}
const EMPTY_VARIANT = { label: '', sku: '', price: '', compare_at: '', stock: 0, image_url: '', is_active: true }
const dollarsOrBlank = (cents) => (cents != null ? (cents / 100).toFixed(2) : '')

const variantRowsFrom = (product) => (product.variants ?? []).map((v) => ({
  id: v.id, label: v.label, sku: v.sku, price: (v.price_cents / 100).toFixed(2), compare_at: dollarsOrBlank(v.compare_at_price_cents),
  stock: v.inventory_quantity, image_url: v.image_url ?? '', is_active: v.is_active,
}))
const EMPTY_CATEGORY = { name: '', slug: '', sort_order: 0, is_active: true }
const EMPTY_STORE = { name: '', line1: '', line2: '', city: '', state: '', postal_code: '', latitude: '', longitude: '', delivery_radius_km: 5, is_active: true }
const riderFormFrom = (rider) => ({
  id: rider.id,
  name: rider.name,
  phone: rider.phone ?? '',
  rider_is_active: !!rider.rider_is_active,
  rider_base_address: rider.rider_base_address ?? '',
  rider_base_lat: rider.rider_base_lat ?? '',
  rider_base_lng: rider.rider_base_lng ?? '',
  daily_target_hours: rider.daily_target_minutes ? String(rider.daily_target_minutes / 60) : '',
  store_ids: (rider.stores ?? []).map((s) => s.id),
})

const RIDER_STATUS = {
  clocked_in: { label: '🟢 On shift', color: '#2f6d34' },
  on_break: { label: '☕ Break', color: '#8a6d2f' },
  paused: { label: '⏸ Paused', color: '#a23b28' },
  off: { label: '⚪ Off the clock', color: '#7c857a' },
  off_roster: { label: '— off roster', color: '#7c857a' },
}
const fmtWorked = (m) => { const n = Math.max(0, Math.round(m || 0)); return n >= 60 ? `${Math.floor(n / 60)}h ${n % 60}m` : `${n}m` }
const DAY_STATUS = {
  full: { label: 'Full', color: '#2f6d34' },
  short: { label: 'Short', color: '#8a6d2f' },
  off: { label: 'Off', color: '#a0a7a0' },
  today: { label: 'Today', color: '#1f5fae' },
  pre: { label: '—', color: '#c0c6c0' },
}

function riderStatusChip(rider) {
  const a = rider.attendance || {}
  const s = RIDER_STATUS[a.status] || RIDER_STATUS.off
  const missed = (rider.declined_count ?? 0) + (rider.missed_count ?? 0)
  return (
    <>
      <span style={{ color: s.color, fontWeight: 600 }}>{s.label}</span>
      {a.today_worked_minutes ? <span className="admin-note">{fmtWorked(a.today_worked_minutes)} today · {fmtWorked(a.week_worked_minutes)} this week</span>
        : a.week_worked_minutes ? <span className="admin-note">{fmtWorked(a.week_worked_minutes)} this week</span> : null}
      {rider.online
        ? <span className="admin-note" style={{ color: '#2f6d34' }}>online now</span>
        : rider.last_seen_at && <span className="admin-note" title={`last seen ${new Date(rider.last_seen_at).toLocaleString()}`}>seen {new Date(rider.last_seen_at).toLocaleDateString()}</span>}
      {a.unavailable_reason && <span className="admin-note" title={a.unavailable_reason}>&ldquo;{a.unavailable_reason}&rdquo;</span>}
      {rider.offers_count > 0 && (
        <span className="admin-note" style={missed > 0 ? { color: '#a23b28' } : undefined} title={`${rider.offers_count} offers · ${rider.declined_count ?? 0} rejected · ${rider.missed_count ?? 0} missed`}>
          {rider.acceptance_rate != null ? `${Math.round(rider.acceptance_rate * 100)}% accepted` : ''}{missed > 0 ? ` · ✗${missed}` : ''}
        </span>
      )}
    </>
  )
}
const EMPTY_BANNER = { image_url: '', headline: '', category_slug: '', link_url: '', placement: 'strip', sort_order: 0, is_active: true }
const EMPTY_TILE = { title: '', image_url: '', category_slug: '', link_url: '', sort_order: 0, is_active: true }
const EMPTY_PAGE = { title: '', slug: '', banner_image: '', content: '', sections: [], footer_group: 'useful_links', show_in_footer: true, is_published: true, sort_order: 0 }
const sectionLabel = (type) => (SECTION_TYPES.find(([value]) => value === type) ?? [type, type])[1]

const dollars = (cents) => ((cents ?? 0) / 100).toFixed(2)
const toCents = (value) => Math.max(0, Math.round(Number(value || 0) * 100))

// Short two-tone chime for a new customer message. Web Audio => no asset/CSP.
function playChime() {
  try {
    const Ctx = window.AudioContext || window.webkitAudioContext
    if (!Ctx) return
    const ctx = new Ctx()
    const blip = (freq, at) => {
      const osc = ctx.createOscillator()
      const gain = ctx.createGain()
      osc.connect(gain); gain.connect(ctx.destination)
      osc.type = 'sine'
      osc.frequency.value = freq
      gain.gain.setValueAtTime(0.0001, ctx.currentTime + at)
      gain.gain.exponentialRampToValueAtTime(0.18, ctx.currentTime + at + 0.02)
      gain.gain.exponentialRampToValueAtTime(0.0001, ctx.currentTime + at + 0.22)
      osc.start(ctx.currentTime + at)
      osc.stop(ctx.currentTime + at + 0.24)
    }
    blip(660, 0)
    blip(990, 0.16)
    setTimeout(() => ctx.close(), 800)
  } catch { /* audio blocked — the toast still shows */ }
}

// Fee settings <-> a dollar/percent form the admin edits.
function feesToForm(s) {
  return {
    delivery_mode: s.delivery_mode ?? 'fixed',
    delivery_fee: dollars(s.delivery_fee_cents),
    delivery_near_fee: dollars(s.delivery_near_fee_cents),
    delivery_far_fee: dollars(s.delivery_far_fee_cents),
    free_delivery_threshold: dollars(s.free_delivery_threshold_cents),
    handling_fee: dollars(s.handling_fee_cents),
    small_cart_fee: dollars(s.small_cart_fee_cents),
    small_cart_min: dollars(s.small_cart_min_cents),
    tax_rate_pct: ((s.tax_rate_bps ?? 0) / 100).toFixed(2),
  }
}

function formToFees(f) {
  return {
    delivery_mode: f.delivery_mode,
    delivery_fee_cents: toCents(f.delivery_fee),
    delivery_near_fee_cents: toCents(f.delivery_near_fee),
    delivery_far_fee_cents: toCents(f.delivery_far_fee),
    free_delivery_threshold_cents: toCents(f.free_delivery_threshold),
    handling_fee_cents: toCents(f.handling_fee),
    small_cart_fee_cents: toCents(f.small_cart_fee),
    small_cart_min_cents: toCents(f.small_cart_min),
    tax_rate_bps: Math.max(0, Math.min(10000, Math.round(Number(f.tax_rate_pct || 0) * 100))),
  }
}

async function readJson(response) {
  const text = await response.text()
  if (!text) return {}
  const start = Math.min(...['{', '['].map((token) => {
    const index = text.indexOf(token)
    return index === -1 ? text.length : index
  }))
  return JSON.parse(text.slice(start))
}

export default function Admin({ token, onClose }) {
  const [tab, setTab] = useState('dashboard')
  const [navOpen, setNavOpen] = useState(() => {
    try { return localStorage.getItem('gdp_admin_nav') !== '0' } catch { return true }
  })
  const [metrics, setMetrics] = useState(null)
  const [chart, setChart] = useState(null)
  const [chartBucket, setChartBucket] = useState('day')
  const [chartMetric, setChartMetric] = useState('orders') // 'orders' | 'revenue_cents'
  const [compare, setCompare] = useState(null)
  const [comparePreset, setComparePreset] = useState('month')
  const [compareDays, setCompareDays] = useState(7)
  const [compareDaysDraft, setCompareDaysDraft] = useState('7')
  const [compareMetric, setCompareMetric] = useState('orders') // 'orders' | 'revenue_cents'
  const [insights, setInsights] = useState(null)
  const [orders, setOrders] = useState([])
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [customers, setCustomers] = useState([])
  const [customerDetail, setCustomerDetail] = useState(null)
  const [statusFilter, setStatusFilter] = useState('all')
  const [productSearch, setProductSearch] = useState('')
  const [productSort, setProductSort] = useState('newest')
  const [productStore, setProductStore] = useState('')
  // Rows per page — shared across every list, remembered per browser.
  const [pageSize, setPageSizeRaw] = useState(() => {
    const n = Number(localStorage.getItem('gdp_admin_page_size'))
    return PAGE_SIZES.includes(n) ? n : 10
  })
  // Server-paginated lists: current page + the server's meta.
  const [ordersPage, setOrdersPage] = useState(1)
  const [ordersMeta, setOrdersMeta] = useState(null)
  const [productsPage, setProductsPage] = useState(1)
  const [productsMeta, setProductsMeta] = useState(null)
  const [customersPage, setCustomersPage] = useState(1)
  const [customersMeta, setCustomersMeta] = useState(null)
  // Small lists paged client-side.
  const [categoriesPage, setCategoriesPage] = useState(1)
  const [ridersPage, setRidersPage] = useState(1)
  const [storesPage, setStoresPage] = useState(1)
  const setPageSize = useCallback((n) => {
    setPageSizeRaw(n)
    try { localStorage.setItem('gdp_admin_page_size', String(n)) } catch { /* private mode */ }
    setOrdersPage(1); setProductsPage(1); setCustomersPage(1)
    setCategoriesPage(1); setRidersPage(1); setStoresPage(1)
  }, [])
  const pageSlice = (list, page) => list.slice((page - 1) * pageSize, page * pageSize)
  const [productForm, setProductForm] = useState(null)
  const [categoryForm, setCategoryForm] = useState(null)
  const [stores, setStores] = useState([])
  const [storeForm, setStoreForm] = useState(null)
  const [banners, setBanners] = useState([])
  const [bannerForm, setBannerForm] = useState(null)
  const [homeTiles, setHomeTiles] = useState([])
  const [tileForm, setTileForm] = useState(null)
  const [pages, setPages] = useState([])
  const [pageForm, setPageForm] = useState(null)
  const [pagePreview, setPagePreview] = useState(false)
  const [pagesExpanded, setPagesExpanded] = useState(false)
  const [blogsExpanded, setBlogsExpanded] = useState(false)
  const [courierDraft, setCourierDraft] = useState({})
  const [riders, setRiders] = useState([])
  const [riderForm, setRiderForm] = useState(null)
  const [riderEmail, setRiderEmail] = useState('')
  const [riderDetail, setRiderDetail] = useState(null)
  const [riderMonth, setRiderMonth] = useState(() => { const d = new Date(); return new Date(d.getFullYear(), d.getMonth(), 1) })
  const [riderReport, setRiderReport] = useState(null)
  const [settings, setSettings] = useState(null)
  const [feesForm, setFeesForm] = useState(null)
  const [brandingForm, setBrandingForm] = useState(null)
  const [footerForm, setFooterForm] = useState(null)
  const [paymentsForm, setPaymentsForm] = useState(null)
  const [accountForm, setAccountForm] = useState({ name: '', email: '', phone: '' })
  const [secureGate, setSecureGate] = useState('locked') // locked | code | unlocked
  const [secureSecret, setSecureSecret] = useState('') // password or OTP code
  const [secureToken, setSecureToken] = useState('')
  const [secureMsg, setSecureMsg] = useState('')
  const [imgBusy, setImgBusy] = useState(false)
  const [threads, setThreads] = useState([])
  const [threadStatus, setThreadStatus] = useState('open')
  const [thread, setThread] = useState(null)
  const [threadReply, setThreadReply] = useState('')
  const [refundForm, setRefundForm] = useState({ items: [], amount: '', reason: '' })
  const [supportBadge, setSupportBadge] = useState(0)
  const [supportToasts, setSupportToasts] = useState([])
  const [soundMuted, setSoundMuted] = useState(() => { try { return localStorage.getItem('gdp_support_muted') === '1' } catch { return false } })
  const seenRef = useRef(null)
  const [busyId, setBusyId] = useState(null)
  const [message, setMessage] = useState('')
  // Per-list "fetch in flight" flags so a slow API shows "Loading…" instead of
  // an empty-result message.
  const [listBusy, setListBusy] = useState({})
  // Flip the flag on a microtask so this isn't a synchronous setState when a
  // loader is called straight from an effect; clear it when the fetch settles.
  const track = useCallback((key, promise) => {
    Promise.resolve().then(() => setListBusy((b) => ({ ...b, [key]: true })))
    return promise.finally(() => setListBusy((b) => ({ ...b, [key]: false })))
  }, [])

  const authHeaders = useCallback(() => ({ Accept: 'application/json', Authorization: `Bearer ${token}` }), [token])
  const jsonHeaders = useCallback(() => ({ ...authHeaders(), 'Content-Type': 'application/json' }), [authHeaders])

  const fail = (error) => setMessage(error?.message ?? 'Something went wrong.')

  const loadMetrics = useCallback(() => {
    fetch(`${API_URL}/admin/metrics`, { headers: authHeaders() }).then(readJson)
      .then((data) => setMetrics(data.data)).catch(() => setMessage('Could not load dashboard metrics.'))
  }, [authHeaders])

  const loadChart = useCallback(() => {
    fetch(`${API_URL}/admin/metrics/timeseries?bucket=${chartBucket}`, { headers: authHeaders() }).then(readJson)
      .then((data) => setChart(data.data)).catch(() => setMessage('Could not load the orders chart.'))
  }, [authHeaders, chartBucket])

  const loadCompare = useCallback(() => {
    const query = comparePreset === 'custom' ? `preset=custom&days=${compareDays}` : `preset=${comparePreset}`
    fetch(`${API_URL}/admin/metrics/compare?${query}`, { headers: authHeaders() }).then(readJson)
      .then((data) => setCompare(data.data)).catch(() => setMessage('Could not load period comparisons.'))
  }, [authHeaders, comparePreset, compareDays])

  const loadInsights = useCallback(() => {
    fetch(`${API_URL}/admin/metrics/insights`, { headers: authHeaders() }).then(readJson)
      .then((data) => setInsights(data.data)).catch(() => setMessage('Could not load dashboard insights.'))
  }, [authHeaders])

  const loadOrders = useCallback(() => {
    const qs = new URLSearchParams({ page: ordersPage, per_page: pageSize })
    if (statusFilter !== 'all') qs.set('status', statusFilter)
    track('orders', fetch(`${API_URL}/admin/orders?${qs}`, { headers: authHeaders() }).then(readJson)
      .then((data) => { setOrders(data.data ?? []); setOrdersMeta(data.meta ?? null) }).catch(() => setMessage('Could not load orders.')))
    fetch(`${API_URL}/admin/riders`, { headers: authHeaders() }).then(readJson)
      .then((data) => setRiders(data.data ?? [])).catch(() => {})
  }, [authHeaders, statusFilter, ordersPage, pageSize, track])

  const loadProducts = useCallback(() => {
    const qs = new URLSearchParams({ page: productsPage, per_page: pageSize, sort: productSort })
    if (productSearch.trim()) qs.set('search', productSearch.trim())
    if (productStore) qs.set('store_id', productStore)
    track('products', fetch(`${API_URL}/admin/products?${qs}`, { headers: authHeaders() }).then(readJson)
      .then((data) => { setProducts(data.data ?? []); setProductsMeta(data.meta ?? null) }).catch(() => setMessage('Could not load products.')))
  }, [authHeaders, productSearch, productSort, productStore, productsPage, pageSize, track])

  const loadCategories = useCallback(() => {
    track('categories', fetch(`${API_URL}/admin/categories`, { headers: authHeaders() }).then(readJson)
      .then((data) => setCategories(data.data ?? [])).catch(() => setMessage('Could not load categories.')))
  }, [authHeaders, track])

  const loadCustomers = useCallback(() => {
    const qs = new URLSearchParams({ page: customersPage, per_page: pageSize })
    track('customers', fetch(`${API_URL}/admin/customers?${qs}`, { headers: authHeaders() }).then(readJson)
      .then((data) => { setCustomers(data.data ?? []); setCustomersMeta(data.meta ?? null) }).catch(() => setMessage('Could not load customers.')))
  }, [authHeaders, customersPage, pageSize, track])

  const loadRiders = useCallback(() => {
    track('riders', fetch(`${API_URL}/admin/riders`, { headers: authHeaders() }).then(readJson)
      .then((data) => setRiders(data.data ?? [])).catch(() => setMessage('Could not load riders.')))
  }, [authHeaders, track])

  const loadSettings = useCallback(() => {
    fetch(`${API_URL}/admin/settings`, { headers: authHeaders() }).then(readJson)
      .then((data) => {
        setSettings(data.data)
        setFeesForm(feesToForm(data.data))
        setBrandingForm({ ...EMPTY_BRANDING, ...(data.data.branding ?? {}) })
        setFooterForm({ ...EMPTY_FOOTER, ...(data.data.footer ?? {}), socials: { ...EMPTY_FOOTER.socials, ...(data.data.footer?.socials ?? {}) }, links: (data.data.footer?.links ?? []).map((l) => ({ ...l })) })
        setPaymentsForm({ stripe_key: data.data.payments?.stripe_key ?? '', stripe_secret: '', stripe_webhook_secret: '' })
      })
      .catch(() => setMessage('Could not load settings.'))
  }, [authHeaders])

  const loadStores = useCallback(() => {
    track('stores', fetch(`${API_URL}/admin/stores`, { headers: authHeaders() }).then(readJson)
      .then((data) => setStores(data.data ?? [])).catch(() => setMessage('Could not load stores.')))
  }, [authHeaders, track])

  const loadBanners = useCallback(() => {
    fetch(`${API_URL}/admin/banners`, { headers: authHeaders() }).then(readJson)
      .then((data) => setBanners(data.data ?? [])).catch(() => setMessage('Could not load banners.'))
  }, [authHeaders])

  const loadHomeTiles = useCallback(() => {
    fetch(`${API_URL}/admin/home-tiles`, { headers: authHeaders() }).then(readJson)
      .then((data) => setHomeTiles(data.data ?? [])).catch(() => setMessage('Could not load homepage tiles.'))
  }, [authHeaders])

  const loadPages = useCallback(() => {
    fetch(`${API_URL}/admin/pages`, { headers: authHeaders() }).then(readJson)
      .then((data) => setPages(data.data ?? [])).catch(() => setMessage('Could not load pages.'))
  }, [authHeaders])

  const loadThreads = useCallback(() => {
    const query = threadStatus === 'all' ? '' : `?status=${threadStatus}`
    fetch(`${API_URL}/admin/support/threads${query}`, { headers: authHeaders() }).then(readJson)
      .then((data) => setThreads(data.data ?? [])).catch(() => setMessage('Could not load support threads.'))
  }, [authHeaders, threadStatus])

  useEffect(() => { if (tab === 'dashboard') loadMetrics() }, [tab, loadMetrics])
  useEffect(() => { loadPages() }, [loadPages])
  useEffect(() => { if (tab === 'dashboard') loadChart() }, [tab, loadChart])
  useEffect(() => { if (tab === 'dashboard') loadCompare() }, [tab, loadCompare])
  useEffect(() => { if (tab === 'dashboard') loadInsights() }, [tab, loadInsights])
  useEffect(() => { if (tab === 'orders') loadOrders() }, [tab, loadOrders])
  // Keep the Orders board current so rider accept / reject / timeout shows within
  // seconds (and each poll drives the server-side offer-timeout sweep).
  useEffect(() => {
    if (tab !== 'orders') return undefined
    const t = setInterval(loadOrders, 15000)
    return () => clearInterval(t)
  }, [tab, loadOrders])
  useEffect(() => { if (tab === 'products') { loadProducts(); loadCategories(); loadStores() } }, [tab, loadProducts, loadCategories, loadStores])
  useEffect(() => { if (tab === 'categories') loadCategories() }, [tab, loadCategories])
  useEffect(() => { if (tab === 'customers') loadCustomers() }, [tab, loadCustomers])
  useEffect(() => { if (tab === 'riders') { loadRiders(); loadStores() } }, [tab, loadRiders, loadStores])
  useEffect(() => { if (tab === 'stores') loadStores() }, [tab, loadStores])
  useEffect(() => { if (tab === 'homepage') { loadBanners(); loadHomeTiles(); loadCategories() } }, [tab, loadBanners, loadHomeTiles, loadCategories])
  useEffect(() => { if (tab === 'support') loadThreads() }, [tab, loadThreads])
  const threadId = thread?.id ?? null
  useEffect(() => {
    if (!threadId) return
    const timer = setInterval(() => {
      fetch(`${API_URL}/admin/support/threads/${threadId}`, { headers: authHeaders() }).then(readJson)
        .then((data) => setThread((cur) => (cur && cur.id === data.data.id ? data.data : cur))).catch(() => {})
    }, 5000)
    return () => clearInterval(timer)
  }, [threadId, authHeaders])
  useEffect(() => { if (tab === 'settings') { loadSettings(); loadStores() } }, [tab, loadSettings, loadStores])
  useEffect(() => { if (tab === 'branding' || tab === 'secure' || tab === 'footer') loadSettings() }, [tab, loadSettings])

  // Background notification poll — runs on every admin tab so a new customer
  // message chimes and toasts even while working elsewhere.
  useEffect(() => {
    let stopped = false
    const check = async () => {
      try {
        const data = await readJson(await fetch(`${API_URL}/admin/support/threads?status=open`, { headers: authHeaders() }))
        if (stopped) return
        const pending = (data.data ?? []).filter((t) => t.needs_reply)
        setSupportBadge(pending.length)
        const map = Object.fromEntries(pending.map((t) => [t.id, t.last_message_at]))
        if (seenRef.current === null) { seenRef.current = map; return } // seed, don't chime on first load
        const fresh = pending.filter((t) => seenRef.current[t.id] !== t.last_message_at)
        seenRef.current = map
        if (fresh.length) {
          if (!soundMuted) playChime()
          setSupportToasts((cur) => [
            ...fresh.map((t) => ({ id: t.id, text: `New message${t.order_id ? ` · order #${t.order_id}` : ''} — ${t.user?.email ?? 'customer'}` })),
            ...cur,
          ].slice(0, 4))
        }
      } catch { /* keep last */ }
    }
    // Delay the first poll so it doesn't compete with the tab's own requests
    // on a single-threaded dev server.
    const kick = setTimeout(check, 2500)
    const timer = setInterval(check, 10000)
    return () => { stopped = true; clearTimeout(kick); clearInterval(timer) }
  }, [authHeaders, soundMuted])

  async function saveStore(event) {
    event.preventDefault()
    setMessage('')
    const { id, latitude, longitude, ...rest } = storeForm
    const payload = { ...rest, delivery_radius_km: Number(rest.delivery_radius_km) }
    if (String(latitude).trim() !== '' && String(longitude).trim() !== '') {
      payload.latitude = Number(latitude)
      payload.longitude = Number(longitude)
    }
    try {
      const response = await fetch(`${API_URL}/admin/stores${id ? `/${id}` : ''}`, { method: id ? 'PATCH' : 'POST', headers: jsonHeaders(), body: JSON.stringify(payload) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Could not save the store.')
      setStoreForm(null)
      loadStores()
    } catch (error) { fail(error) }
  }

  async function removeStore(store) {
    if (!window.confirm(`Delete ${store.name}?`)) return
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/stores/${store.id}`, { method: 'DELETE', headers: authHeaders() })
      if (!response.ok && response.status !== 204) throw new Error((await readJson(response)).message ?? 'Could not delete the store.')
      loadStores()
    } catch (error) { fail(error) }
  }

  async function addRider(event) {
    event.preventDefault()
    setMessage('')
    const email = riderEmail.trim()
    if (!email) return
    try {
      const response = await fetch(`${API_URL}/admin/riders`, { method: 'POST', headers: jsonHeaders(), body: JSON.stringify({ email }) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Could not add the rider.')
      setRiderEmail('')
      loadRiders()
      setRiderForm(riderFormFrom(data.data))
    } catch (error) { fail(error) }
  }

  async function patchRider(rider, body) {
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/riders/${rider.id}`, { method: 'PATCH', headers: jsonHeaders(), body: JSON.stringify(body) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Could not update the rider.')
      setRiders((cur) => cur.map((r) => (r.id === rider.id ? data.data : r)))
    } catch (error) { fail(error) }
  }

  async function saveRider(event) {
    event.preventDefault()
    setMessage('')
    const f = riderForm
    const payload = {
      phone: f.phone.trim() || null,
      rider_is_active: f.rider_is_active,
      rider_base_address: f.rider_base_address.trim() || null,
      rider_base_lat: String(f.rider_base_lat).trim() === '' ? null : Number(f.rider_base_lat),
      rider_base_lng: String(f.rider_base_lng).trim() === '' ? null : Number(f.rider_base_lng),
      rider_daily_target_minutes: String(f.daily_target_hours).trim() === '' ? null : Math.round(Number(f.daily_target_hours) * 60),
      store_ids: f.store_ids.map(Number),
    }
    try {
      const response = await fetch(`${API_URL}/admin/riders/${f.id}`, { method: 'PATCH', headers: jsonHeaders(), body: JSON.stringify(payload) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Could not save the rider.')
      setRiderForm(null)
      loadRiders()
    } catch (error) { fail(error) }
  }

  async function removeRider(rider) {
    if (!window.confirm(`Remove the rider role from ${rider.name}? Their account stays.`)) return
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/riders/${rider.id}`, { method: 'DELETE', headers: authHeaders() })
      if (!response.ok && response.status !== 204) throw new Error((await readJson(response)).message ?? 'Could not remove the rider.')
      if (riderForm?.id === rider.id) setRiderForm(null)
      loadRiders()
    } catch (error) { fail(error) }
  }

  async function saveBanner(event) {
    event.preventDefault()
    setMessage('')
    const { id, ...rest } = bannerForm
    const payload = {
      ...rest,
      headline: rest.headline.trim() || null,
      category_slug: rest.category_slug || null,
      link_url: rest.link_url.trim() || null,
      sort_order: Number(rest.sort_order) || 0,
    }
    try {
      const response = await fetch(`${API_URL}/admin/banners${id ? `/${id}` : ''}`, { method: id ? 'PATCH' : 'POST', headers: jsonHeaders(), body: JSON.stringify(payload) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Could not save the banner.')
      setBannerForm(null)
      loadBanners()
    } catch (error) { fail(error) }
  }

  async function removeBanner(banner) {
    if (!window.confirm('Delete this banner?')) return
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/banners/${banner.id}`, { method: 'DELETE', headers: authHeaders() })
      if (!response.ok && response.status !== 204) throw new Error((await readJson(response)).message ?? 'Could not delete the banner.')
      loadBanners()
    } catch (error) { fail(error) }
  }

  async function saveTile(event) {
    event.preventDefault()
    setMessage('')
    const { id, ...rest } = tileForm
    const payload = {
      ...rest,
      title: rest.title.trim() || null,
      image_url: rest.image_url.trim() || null,
      category_slug: rest.category_slug || null,
      link_url: rest.link_url.trim() || null,
      sort_order: Number(rest.sort_order) || 0,
    }
    try {
      const response = await fetch(`${API_URL}/admin/home-tiles${id ? `/${id}` : ''}`, { method: id ? 'PATCH' : 'POST', headers: jsonHeaders(), body: JSON.stringify(payload) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Could not save the tile.')
      setTileForm(null)
      loadHomeTiles()
    } catch (error) { fail(error) }
  }

  async function removeTile(tile) {
    if (!window.confirm('Delete this homepage tile?')) return
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/home-tiles/${tile.id}`, { method: 'DELETE', headers: authHeaders() })
      if (!response.ok && response.status !== 204) throw new Error((await readJson(response)).message ?? 'Could not delete the tile.')
      loadHomeTiles()
    } catch (error) { fail(error) }
  }

  const scrollAdminTop = () => {
    requestAnimationFrame(() => {
      document.querySelector('.admin-main')?.scrollTo({ top: 0, behavior: 'smooth' })
      window.scrollTo({ top: 0, behavior: 'smooth' })
    })
  }

  function editPage(page) {
    setPagePreview(false)
    setPageForm({
      id: page.id, title: page.title ?? '', slug: page.slug ?? '', banner_image: page.banner_image ?? '',
      content: page.content ?? '',
      sections: Array.isArray(page.sections) ? page.sections : [],
      footer_group: page.footer_group ?? 'useful_links', show_in_footer: page.show_in_footer,
      is_published: page.is_published, sort_order: page.sort_order ?? 0,
    })
    scrollAdminTop()
  }

  function newPage(extra = {}) {
    setPagePreview(false)
    setPageForm({ ...EMPTY_PAGE, ...extra })
    scrollAdminTop()
  }

  async function savePage(event) {
    event.preventDefault()
    setMessage('')
    const { id, ...rest } = pageForm
    const payload = { ...rest, slug: rest.slug.trim(), sort_order: Number(rest.sort_order) || 0 }
    try {
      const response = await fetch(`${API_URL}/admin/pages${id ? `/${id}` : ''}`, { method: id ? 'PATCH' : 'POST', headers: jsonHeaders(), body: JSON.stringify(payload) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Could not save the page.')
      setPageForm(null)
      loadPages()
    } catch (error) { fail(error) }
  }

  const patchSection = (i, patch) => setPageForm((f) => ({ ...f, sections: f.sections.map((s, idx) => (idx === i ? { ...s, ...patch } : s)) }))
  const addSection = (type) => setPageForm((f) => ({ ...f, sections: [...(f.sections ?? []), blankSection(type)] }))
  const removeSection = (i) => setPageForm((f) => ({ ...f, sections: f.sections.filter((_, idx) => idx !== i) }))
  const moveSection = (i, dir) => setPageForm((f) => {
    const next = [...f.sections]
    const j = i + dir
    if (j < 0 || j >= next.length) return f
    ;[next[i], next[j]] = [next[j], next[i]]
    return { ...f, sections: next }
  })
  const patchItem = (si, ii, patch) => setPageForm((f) => ({ ...f, sections: f.sections.map((s, idx) => (idx === si ? { ...s, items: (s.items ?? []).map((it, k) => (k === ii ? { ...it, ...patch } : it)) } : s)) }))
  const addItem = (si) => setPageForm((f) => ({ ...f, sections: f.sections.map((s, idx) => (idx === si ? { ...s, items: [...(s.items ?? []), { image_url: '', title: '', text: '', link_url: '' }] } : s)) }))
  const removeItem = (si, ii) => setPageForm((f) => ({ ...f, sections: f.sections.map((s, idx) => (idx === si ? { ...s, items: (s.items ?? []).filter((_, k) => k !== ii) } : s)) }))

  async function removePage(page) {
    if (!window.confirm(`Delete the “${page.title}” page?`)) return
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/pages/${page.id}`, { method: 'DELETE', headers: authHeaders() })
      if (!response.ok && response.status !== 204) throw new Error((await readJson(response)).message ?? 'Could not delete the page.')
      if (pageForm?.id === page.id) setPageForm(null)
      loadPages()
    } catch (error) { fail(error) }
  }

  async function saveSetting(patch, extraHeaders = {}) {
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/settings`, { method: 'PATCH', headers: { ...jsonHeaders(), ...extraHeaders }, body: JSON.stringify(patch) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Could not save the setting.')
      setSettings(data.data)
      return data.data
    } catch (error) { fail(error) }
  }

  async function saveFees(event) {
    event.preventDefault()
    const saved = await saveSetting(formToFees(feesForm))
    if (saved) { setFeesForm(feesToForm(saved)); setMessage('Charges saved.') }
  }

  async function saveBranding(event) {
    event.preventDefault()
    const saved = await saveSetting({
      store_name: brandingForm.store_name.trim() || 'Grocerly',
      tagline: brandingForm.tagline.trim(),
      logo_url: brandingForm.logo_url.trim(),
      favicon_url: brandingForm.favicon_url.trim(),
      theme: brandingForm.theme,
      layout_width: brandingForm.layout_width,
      color_brand: brandingForm.color_brand,
      color_accent: brandingForm.color_accent,
      color_heading: brandingForm.color_heading,
    })
    if (saved) { setBrandingForm({ ...EMPTY_BRANDING, ...(saved.branding ?? {}) }); setMessage('Store settings saved — refresh the storefront to see them.') }
  }

  async function saveFooter(event) {
    event.preventDefault()
    const payload = {
      copyright: footerForm.copyright.trim(),
      note: footerForm.note.trim(),
      app_store_url: footerForm.app_store_url.trim(),
      play_store_url: footerForm.play_store_url.trim(),
      socials: footerForm.socials,
      links: footerForm.links.filter((l) => l.label.trim() && l.url.trim()),
    }
    const saved = await saveSetting({ footer: payload })
    if (saved) {
      setFooterForm({ ...EMPTY_FOOTER, ...(saved.footer ?? {}), socials: { ...EMPTY_FOOTER.socials, ...(saved.footer?.socials ?? {}) }, links: (saved.footer?.links ?? []).map((l) => ({ ...l })) })
      setMessage('Footer saved — refresh the storefront to see it.')
    }
  }

  const secureMethod = settings?.secure_access?.method ?? 'password'

  async function challengeSecure() {
    setSecureMsg('Sending a code to your admin email…')
    try {
      const response = await fetch(`${API_URL}/admin/secure-access/challenge`, { method: 'POST', headers: authHeaders() })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Could not send the code.')
      setSecureMsg(data.data?.message ?? 'Check your admin email for the code.')
    } catch (error) { setSecureMsg(error.message) }
  }

  async function unlockSecure() {
    setSecureMsg('')
    const body = secureMethod === 'otp' ? { code: secureSecret.trim() } : { password: secureSecret }
    try {
      const response = await fetch(`${API_URL}/admin/secure-access/unlock`, { method: 'POST', headers: jsonHeaders(), body: JSON.stringify(body) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'That did not work.')
      setSecureToken(data.data.token)
      setSecureSecret('')
      setSecureGate('unlocked')
      if (data.data.account) setAccountForm({ name: data.data.account.name ?? '', email: data.data.account.email ?? '', phone: data.data.account.phone ?? '' })
      if (data.data.payments) setSettings((s) => (s ? { ...s, payments: data.data.payments } : s))
    } catch (error) { setSecureMsg(error.message) }
  }

  async function savePayments(event) {
    event.preventDefault()
    const patch = { stripe_key: paymentsForm.stripe_key.trim() }
    if (paymentsForm.stripe_secret.trim()) patch.stripe_secret = paymentsForm.stripe_secret.trim()
    if (paymentsForm.stripe_webhook_secret.trim()) patch.stripe_webhook_secret = paymentsForm.stripe_webhook_secret.trim()
    const saved = await saveSetting(patch, { 'X-Secure-Access': secureToken })
    if (saved) {
      setPaymentsForm({ stripe_key: saved.payments?.stripe_key ?? '', stripe_secret: '', stripe_webhook_secret: '' })
      setMessage('Payment settings saved — they take effect immediately.')
    } else {
      setSecureGate('locked'); setSecureToken('')
    }
  }

  async function saveAccount(event) {
    event.preventDefault()
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/secure-access/account`, {
        method: 'PATCH', headers: { ...jsonHeaders(), 'X-Secure-Access': secureToken },
        body: JSON.stringify({ name: accountForm.name.trim(), email: accountForm.email.trim(), phone: accountForm.phone.trim() }),
      })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Could not update the account.')
      setAccountForm({ name: data.data.name ?? '', email: data.data.email ?? '', phone: data.data.phone ?? '' })
      setMessage('Admin account updated.')
    } catch (error) {
      fail(error)
      if (error.message === 'Unlock the Secure access section first.') { setSecureGate('locked'); setSecureToken('') }
    }
  }

  async function patchOrder(order, body) {
    setBusyId(order.id)
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/orders/${order.id}`, { method: 'PATCH', headers: jsonHeaders(), body: JSON.stringify(body) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'That change was not allowed.')
      setOrders((current) => current.map((row) => row.id === order.id ? { ...row, ...data.data } : row))
      loadMetrics()
    } catch (error) { fail(error) } finally { setBusyId(null) }
  }

  async function refundOrder(order) {
    if (!window.confirm(`Refund ${money(order.total_cents)} to the customer via Stripe?`)) return
    setBusyId(order.id)
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/orders/${order.id}/refund`, { method: 'POST', headers: authHeaders() })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Refund failed.')
      setOrders((current) => current.map((row) => row.id === order.id ? { ...row, ...data.data } : row))
      setMessage('Refund issued.')
      loadMetrics()
    } catch (error) { fail(error) } finally { setBusyId(null) }
  }

  async function openThread(id) {
    setMessage('')
    setRefundForm({ items: [], amount: '', reason: '' })
    setSupportToasts((cur) => cur.filter((t) => t.id !== id))
    try {
      const data = await readJson(await fetch(`${API_URL}/admin/support/threads/${id}`, { headers: authHeaders() }))
      setThread(data.data)
      if (seenRef.current && data.data.last_message_at) seenRef.current[id] = data.data.last_message_at
    } catch (error) { fail(error) }
  }

  async function replyThread() {
    const body = threadReply.trim()
    if (!body || !thread) return
    try {
      const response = await fetch(`${API_URL}/admin/support/threads/${thread.id}/messages`, { method: 'POST', headers: jsonHeaders(), body: JSON.stringify({ body }) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Message not sent.')
      setThreadReply('')
      setThread(data.data)
    } catch (error) { fail(error) }
  }

  async function setThreadResolved(status) {
    if (!thread) return
    try {
      const response = await fetch(`${API_URL}/admin/support/threads/${thread.id}`, { method: 'PATCH', headers: jsonHeaders(), body: JSON.stringify({ status }) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Could not update.')
      setThread(data.data)
      loadThreads()
    } catch (error) { fail(error) }
  }

  async function issueRefund() {
    if (!thread?.order) return
    const body = { support_thread_id: thread.id, reason: refundForm.reason.trim() || undefined }
    if (refundForm.items.length) body.item_ids = refundForm.items
    else if (refundForm.amount) body.amount_cents = Math.round(Number(refundForm.amount) * 100)
    const label = refundForm.items.length
      ? money(thread.order.items.filter((i) => refundForm.items.includes(i.id)).reduce((s, i) => s + i.line_total_cents, 0))
      : (refundForm.amount ? `$${refundForm.amount}` : money(thread.order.total_cents - (thread.order.refunded_amount_cents ?? 0)))
    if (!window.confirm(`Refund ${label} to the customer via Stripe?`)) return
    setBusyId(thread.id)
    try {
      const response = await fetch(`${API_URL}/admin/orders/${thread.order.id}/refund`, { method: 'POST', headers: jsonHeaders(), body: JSON.stringify(body) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Refund failed.')
      setRefundForm({ items: [], amount: '', reason: '' })
      openThread(thread.id)
      loadMetrics()
      setMessage('Refund issued.')
    } catch (error) { fail(error) } finally { setBusyId(null) }
  }

  async function saveProduct(event) {
    event.preventDefault()
    setMessage('')
    const { id, price, compare_at: compareAt, variants, per_store_stock: perStore, store_stock: storeStockMap, ...rest } = productForm
    const payload = { ...rest, category_id: Number(rest.category_id), inventory_quantity: Number(rest.inventory_quantity), price_cents: Math.round(Number(price) * 100), compare_at_price_cents: String(compareAt).trim() ? Math.round(Number(compareAt) * 100) : null, image_url: rest.image_url?.trim() || null }

    // Per-store stock: a full grid of (store, option) rows. Off = single stock,
    // sent as [] so the backend drops any rows.
    const liveVariants = (variants ?? []).filter((v) => !v._delete && (v.sku || '').trim())
    payload.store_stock = perStore
      ? Object.entries(storeStockMap ?? {}).flatMap(([sid, row]) => {
          const stocked = row.is_stocked !== false
          const base = { store_id: Number(sid), variant_sku: null, is_stocked: stocked, quantity: Number(row.base || 0) }
          const vRows = liveVariants.map((v) => {
            const idx = variants.indexOf(v)
            return { store_id: Number(sid), variant_sku: v.sku.trim(), is_stocked: stocked, quantity: Number(row.variants?.[idx] || 0) }
          })
          return [base, ...vRows]
        })
      : []
    const rows = (variants ?? []).filter((row) => row.id || !row._delete)
    if (id || rows.length) {
      payload.variants = rows.map((row) => ({
        ...(row.id ? { id: row.id } : {}),
        ...(row._delete ? { _delete: true } : {}),
        label: (row.label || '').trim(),
        sku: (row.sku || '').trim(),
        price_cents: Math.round(Number(row.price || 0) * 100),
        compare_at_price_cents: String(row.compare_at ?? '').trim() ? Math.round(Number(row.compare_at) * 100) : null,
        inventory_quantity: Number(row.stock) || 0,
        image_url: row.image_url?.trim() || null,
        is_active: !!row.is_active,
      }))
    }
    try {
      const response = await fetch(`${API_URL}/admin/products${id ? `/${id}` : ''}`, { method: id ? 'PATCH' : 'POST', headers: jsonHeaders(), body: JSON.stringify(payload) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Could not save the product.')
      setProductForm(null)
      loadProducts()
      loadMetrics()
    } catch (error) { fail(error) }
  }

  // Upload an image file to /api/admin/media and hand the stored URL to `apply`.
  async function uploadImage(file, apply) {
    if (!file) return
    setMessage('')
    setImgBusy(true)
    try {
      const body = new FormData()
      body.append('file', file)
      const response = await fetch(`${API_URL}/admin/media`, { method: 'POST', headers: authHeaders(), body })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Upload failed.')
      apply(data.data.url)
    } catch (error) { fail(error) } finally { setImgBusy(false) }
  }

  async function removeProduct(product) {
    if (!window.confirm(`Delete ${product.name}?`)) return
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/products/${product.id}`, { method: 'DELETE', headers: authHeaders() })
      if (!response.ok && response.status !== 204) throw new Error((await readJson(response)).message ?? 'Could not delete the product.')
      loadProducts()
      loadMetrics()
    } catch (error) { fail(error) }
  }

  async function saveCategory(event) {
    event.preventDefault()
    setMessage('')
    const { id, ...rest } = categoryForm
    const payload = { ...rest, sort_order: Number(rest.sort_order) }
    if (!payload.slug) delete payload.slug
    try {
      const response = await fetch(`${API_URL}/admin/categories${id ? `/${id}` : ''}`, { method: id ? 'PATCH' : 'POST', headers: jsonHeaders(), body: JSON.stringify(payload) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Could not save the category.')
      setCategoryForm(null)
      loadCategories()
    } catch (error) { fail(error) }
  }

  async function removeCategory(category) {
    if (!window.confirm(`Delete ${category.name}?`)) return
    setMessage('')
    try {
      const response = await fetch(`${API_URL}/admin/categories/${category.id}`, { method: 'DELETE', headers: authHeaders() })
      if (!response.ok && response.status !== 204) throw new Error((await readJson(response)).message ?? 'Could not delete the category.')
      loadCategories()
    } catch (error) { fail(error) }
  }

  async function openCustomer(id) {
    setMessage('')
    setCustomerDetail({ loading: true })
    try {
      const response = await fetch(`${API_URL}/admin/customers/${id}`, { headers: authHeaders() })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Could not load the customer.')
      setCustomerDetail(data.data)
    } catch (error) { setCustomerDetail(null); fail(error) }
  }

  async function openRiderDetail(id, view = 'full') {
    setMessage('')
    setRiderDetail({ loading: true, view })
    setRiderReport(null)
    setRiderMonth(() => { const d = new Date(); return new Date(d.getFullYear(), d.getMonth(), 1) })
    try {
      const response = await fetch(`${API_URL}/admin/riders/${id}`, { headers: authHeaders() })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Could not load the rider.')
      setRiderDetail({ ...data.data, view })
    } catch (error) { setRiderDetail(null); fail(error) }
  }

  const loadRiderReport = useCallback((riderId, month) => {
    const from = `${month.getFullYear()}-${String(month.getMonth() + 1).padStart(2, '0')}-01`
    const end = new Date(month.getFullYear(), month.getMonth() + 1, 0)
    const to = `${end.getFullYear()}-${String(end.getMonth() + 1).padStart(2, '0')}-${String(end.getDate()).padStart(2, '0')}`
    Promise.resolve().then(() => setRiderReport({ loading: true }))
    return fetch(`${API_URL}/admin/riders/${riderId}/attendance?from=${from}&to=${to}`, { headers: authHeaders() })
      .then(readJson)
      .then((data) => setRiderReport(data?.data ?? null))
      .catch(() => setRiderReport(null))
  }, [authHeaders])

  useEffect(() => {
    const id = riderDetail?.rider?.id
    if (id && riderDetail?.view !== 'reviews') loadRiderReport(id, riderMonth)
  }, [riderDetail?.rider?.id, riderDetail?.view, riderMonth, loadRiderReport])

  async function toggleRider(id, isRider) {
    try {
      const response = await fetch(`${API_URL}/admin/customers/${id}`, { method: 'PATCH', headers: jsonHeaders(), body: JSON.stringify({ is_rider: isRider }) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Could not update.')
      setCustomerDetail((c) => (c && c.id === id ? { ...c, is_rider: data.data.is_rider } : c))
      setCustomers((list) => list.map((c) => (c.id === id ? { ...c, is_rider: data.data.is_rider } : c)))
    } catch (error) { fail(error) }
  }

  const toggleNav = () => setNavOpen((open) => {
    const next = !open
    try { localStorage.setItem('gdp_admin_nav', next ? '1' : '0') } catch { /* ignore */ }
    return next
  })

  const goTab = (name) => {
    // Leaving Secure access re-locks it; entering it starts the challenge fresh.
    if (tab === 'secure' && name !== 'secure') {
      setSecureGate('locked'); setSecureSecret(''); setSecureToken(''); setSecureMsg('')
    }
    if (name === 'secure' && tab !== 'secure') {
      setSecureGate('code'); setSecureSecret(''); setSecureToken(''); setSecureMsg('')
      if ((settings?.secure_access?.method ?? 'password') === 'otp') challengeSecure()
    }
    setTab(name)
    setMessage('')
    // On a narrow screen the sidebar overlays the content — close it after a pick.
    if (typeof window !== 'undefined' && window.matchMedia('(max-width: 860px)').matches) {
      setNavOpen(false)
    }
  }

  return (
    <div className={`admin-shell${navOpen ? '' : ' nav-collapsed'}`}>
      <header className="admin-bar">
        <button className="admin-menu-toggle" type="button" aria-label={navOpen ? 'Hide menu' : 'Show menu'} aria-expanded={navOpen} onClick={toggleNav}>☰</button>
        <div className="admin-brand"><span>g</span> Admin console</div>
        <div className="admin-bar-right">
          {TOP_TABS.map((name) => (
            <button key={name} type="button" className={`admin-top-tab${tab === name ? ' active' : ''}`} onClick={() => goTab(name)}>
              {TAB_LABELS[name]}{name === 'support' && supportBadge > 0 && <span className="tab-badge">{supportBadge}</span>}
            </button>
          ))}
          <button className="admin-close soundtoggle" type="button" title={soundMuted ? 'Unmute chat sound' : 'Mute chat sound'} onClick={() => setSoundMuted((m) => { const next = !m; try { localStorage.setItem('gdp_support_muted', next ? '1' : '0') } catch { /* ignore */ } return next })}>{soundMuted ? '🔕' : '🔔'}</button>
          <button className="admin-close" type="button" onClick={onClose}>Back to store</button>
        </div>
      </header>

      {supportToasts.length > 0 && (
        <div className="admin-toasts">
          {supportToasts.map((t) => (
            <button key={`${t.id}-${t.text}`} type="button" className="admin-toast" onClick={() => { goTab('support'); openThread(t.id) }}>
              💬 {t.text} <span>Open →</span>
            </button>
          ))}
        </div>
      )}

      <div className="admin-body">
        <nav className="admin-sidebar" aria-label="Admin sections">
          {PRIMARY_TABS.map((name) => (
            <button key={name} type="button" className={tab === name ? 'active' : ''} onClick={() => goTab(name)}>
              <span className="nav-ico" aria-hidden>{TAB_ICONS[name]}</span>
              <span className="nav-label">{TAB_LABELS[name]}</span>
            </button>
          ))}

          {(() => { const inGroup = tab === 'pages' || tab === 'homepage' || tab === 'footer'; const open = pagesExpanded || inGroup; return <>
          <button type="button" className={`nav-group-toggle${inGroup ? ' active' : ''}`} aria-expanded={open} onClick={() => setPagesExpanded((v) => !v)}>
            <span className="nav-ico" aria-hidden>{'\u{1F4C4}'}</span>
            <span className="nav-label">Pages</span>
            <span className="nav-caret" aria-hidden>{open ? '▾' : '▸'}</span>
          </button>
          {open && (
            <div className="admin-nav-sub">
              <button type="button" className={tab === 'homepage' ? 'active' : ''} onClick={() => goTab('homepage')}>Homepage</button>
              <button type="button" className={tab === 'footer' ? 'active' : ''} onClick={() => goTab('footer')}>Footer</button>
              <button type="button" className={tab === 'pages' && !pageForm ? 'active' : ''} onClick={() => { goTab('pages'); setPageForm(null) }}>All pages</button>
              {pages.filter((p) => p.footer_group !== 'blog').map((p) => (
                <button key={p.id} type="button" className={tab === 'pages' && pageForm?.id === p.id ? 'active' : ''} onClick={() => { goTab('pages'); editPage(p) }}>{p.title}</button>
              ))}
              <button type="button" className="nav-sub-add" onClick={() => { goTab('pages'); newPage() }}>+ New page</button>
              {(() => { const blogPages = pages.filter((p) => p.footer_group === 'blog'); const blogOpen = blogsExpanded || (tab === 'pages' && pageForm?.footer_group === 'blog'); return <>
                <button type="button" className="nav-subgroup-toggle" aria-expanded={blogOpen} onClick={() => setBlogsExpanded((v) => !v)}>Blogs<span className="nav-caret" aria-hidden>{blogOpen ? '▾' : '▸'}</span></button>
                {blogOpen && (
                  <div className="admin-nav-sub">
                    {blogPages.length === 0 && <button type="button" disabled className="nav-sub-empty">No blog posts</button>}
                    {blogPages.map((p) => (
                      <button key={p.id} type="button" className={tab === 'pages' && pageForm?.id === p.id ? 'active' : ''} onClick={() => { goTab('pages'); editPage(p) }}>{p.title}</button>
                    ))}
                    <button type="button" className="nav-sub-add" onClick={() => { goTab('pages'); newPage({ footer_group: 'blog', show_in_footer: false }) }}>+ New blog post</button>
                  </div>
                )}
              </> })()}
            </div>
          )}
          </> })()}
        </nav>
        <div className="admin-nav-scrim" role="presentation" onClick={() => setNavOpen(false)} />

        <main className="admin-main">
      {message && <p className="admin-message">{message}</p>}

      {tab === 'dashboard' && (
        <>
          <section className="admin-grid">
            {!metrics ? <p className="admin-empty">Loading metrics...</p> : (
              <>
                <article className="metric accent"><span>Paid revenue</span><strong>{money(metrics.revenue_cents)}</strong></article>
                <article className="metric"><span>Orders</span><strong>{metrics.orders_total}</strong></article>
                <article className="metric"><span>Avg order value</span><strong>{money(metrics.avg_order_cents ?? 0)}</strong></article>
                <article className="metric"><span>Awaiting fulfilment</span><strong>{metrics.awaiting_fulfilment}</strong></article>
                <article className="metric"><span>COD orders</span><strong>{metrics.cod_orders ?? 0}</strong></article>
                <article className="metric"><span>Discounts given</span><strong>{money(metrics.discount_cents ?? 0)}</strong></article>
                <article className="metric"><span>Refunded</span><strong>{money(metrics.refunded_cents ?? 0)}</strong></article>
                <article className="metric"><span>Customers</span><strong>{metrics.customers}</strong></article>
                <article className="metric"><span>Products</span><strong>{metrics.products}</strong></article>
                <article className="metric"><span>Low stock (&le;5)</span><strong>{metrics.low_stock}</strong></article>
              </>
            )}
          </section>

          <section className="admin-panel">
            <h3 className="admin-subhead">Orders trend</h3>
            <div className="chart-toolbar">
              <div className="seg" role="group" aria-label="Time basis">
                {[['day', 'Daily'], ['week', 'Weekly'], ['month', 'Monthly']].map(([value, label]) => (
                  <button key={value} type="button" className={chartBucket === value ? 'active' : ''} onClick={() => { setChart(null); setChartBucket(value) }}>{label}</button>
                ))}
              </div>
              <div className="seg" role="group" aria-label="Measure">
                {[['orders', 'Orders'], ['revenue_cents', 'Revenue']].map(([value, label]) => (
                  <button key={value} type="button" className={chartMetric === value ? 'active' : ''} onClick={() => setChartMetric(value)}>{label}</button>
                ))}
              </div>
              {chart && <span className="muted chart-range">{chart.from} → {chart.to} · {chart.totals.orders} orders · {chart.totals.paid_orders} paid · {money(chart.totals.revenue_cents)}</span>}
            </div>

            {!chart ? <p className="admin-empty">Loading chart…</p> : (
              <>
                <LineChart
                  series={chart.series.map((row) => ({ label: row.label, value: chartMetric === 'orders' ? row.orders : row.revenue_cents }))}
                  format={chartMetric === 'orders' ? ((v) => v) : money}
                />
                <div className="chart-pies">
                  <div>
                    <h4 className="admin-subhead">Orders by status</h4>
                    <PieChart data={Object.entries(chart.by_status).map(([status, count]) => ({ label: STATUS_LABELS[status] ?? status, value: count }))} />
                  </div>
                  <div>
                    <h4 className="admin-subhead">Orders by payment</h4>
                    <PieChart data={Object.entries(chart.by_payment_method).map(([method, count]) => ({ label: method === 'cod' ? 'Cash on delivery' : 'Card', value: count }))} />
                  </div>
                </div>
              </>
            )}
          </section>

          <section className="admin-panel">
            <h3 className="admin-subhead">When orders come in</h3>
            {!insights ? <p className="admin-empty">Loading…</p> : (
              <>
                <Heatmap
                  rows={insights.activity?.rows ?? []}
                  matrix={insights.activity?.matrix ?? []}
                  peak={insights.activity?.peak ?? 0}
                  cols={['00:00', '23:00']}
                  cellTitle={(r, c, v) => `${(insights.activity?.rows ?? [])[r]} ${String(c).padStart(2, '0')}:00 — ${v} order${v === 1 ? '' : 's'}`}
                />
                <p className="muted chart-range">Orders by weekday and hour &middot; since {insights.activity?.since ?? ''}</p>
              </>
            )}
          </section>

          <section className="admin-panel admin-panel-compare">
           <div className="dash-split">
            <div className="dash-split-main">
            <h3 className="admin-subhead">Compared to the previous period</h3>
            <div className="chart-toolbar">
              <select className="admin-select" value={comparePreset} onChange={(event) => { setCompare(null); setComparePreset(event.target.value) }} aria-label="Comparison period">
                <option value="day">Today vs yesterday</option>
                <option value="two_day">Last 2 days vs previous 2 days</option>
                <option value="week">This week vs last week</option>
                <option value="month">This month vs last month</option>
                <option value="six_month">Last 6 months vs previous 6 months</option>
                <option value="year">This year vs last year</option>
                <option value="custom">Custom days…</option>
              </select>
              {comparePreset === 'custom' && (
                <form className="compare-custom" onSubmit={(event) => { event.preventDefault(); const n = Math.max(1, Math.min(730, Number(compareDaysDraft) || 0)); if (n) { setCompare(null); setCompareDays(n) } }}>
                  <input type="number" min="1" max="730" value={compareDaysDraft} onChange={(event) => setCompareDaysDraft(event.target.value)} aria-label="Number of days" />
                  <span className="muted">days each side</span>
                  <button className="act" type="submit">Apply</button>
                </form>
              )}
              <div className="seg" role="group" aria-label="Measure">
                {[['orders', 'Orders'], ['revenue_cents', 'Revenue']].map(([value, label]) => (
                  <button key={value} type="button" className={compareMetric === value ? 'active' : ''} onClick={() => setCompareMetric(value)}>{label}</button>
                ))}
              </div>
            </div>

            {!compare ? <p className="admin-empty">Loading comparison…</p> : (() => {
              const fmt = compareMetric === 'orders' ? ((v) => v) : money
              const cur = compare.current[compareMetric]
              const prev = compare.previous[compareMetric]
              return (
                <>
                  <div className="compare-head">
                    <div><span className="compare-measure">{compare.current.label}{compare.partial ? ' (so far)' : ''}</span><strong>{fmt(cur)}</strong></div>
                    <Delta current={cur} previous={prev} />
                    <div className="compare-vs"><span className="compare-measure">{compare.previous.label} (full)</span><strong>{fmt(prev)}</strong></div>
                  </div>
                  <PieChart
                    format={fmt}
                    data={[
                      { label: `${compare.current.label}${compare.partial ? ' (so far)' : ''}`, value: cur },
                      { label: `${compare.previous.label} (full)`, value: prev },
                    ]}
                  />
                </>
              )
            })()}
            </div>
            <div className="dash-split-side">
              <h3 className="admin-subhead">Payments vs refunds</h3>
              {!metrics ? <p className="admin-empty">Loading…</p> : (
                <PieChart
                  format={money}
                  data={[
                    { label: 'Payments', value: metrics.revenue_cents },
                    { label: 'Refunds', value: metrics.refunded_cents ?? 0 },
                  ]}
                />
              )}
            </div>
           </div>
          </section>
        </>
      )}

      {tab === 'orders' && (
        <section className="admin-panel">
          <div className="admin-filters">
            {STATUS_FILTERS.map((value) => (
              <button key={value} type="button" className={statusFilter === value ? 'chip active' : 'chip'} onClick={() => { setStatusFilter(value); setOrdersPage(1) }}>
                {value === 'all' ? 'All' : STATUS_LABELS[value]}
              </button>
            ))}
          </div>
          {listBusy.orders && orders.length === 0 ? <p className="admin-empty">Loading orders…</p> : orders.length === 0 ? <p className="admin-empty">No orders for this filter.</p> : (
            <table className="admin-table">
              <thead><tr><th>#</th><th>Customer</th><th>Placed</th><th>Total</th><th>Payment</th><th>Delivery</th><th>Courier</th><th>Actions</th></tr></thead>
              <tbody>
                {orders.map((order) => (
                  <tr key={order.id}>
                    <td>{order.id}</td>
                    <td>{order.user?.email ?? '—'}{(order.delivery_address?.phone || order.user?.phone) && <span className="admin-note">☎ {order.delivery_address?.phone || order.user?.phone}</span>}{order.delivery_instructions && <span className="admin-note" title={order.delivery_instructions}>&ldquo;{order.delivery_instructions}&rdquo;</span>}</td>
                    <td>{new Date(order.created_at).toLocaleDateString()}</td>
                    <td>{money(order.total_cents)}<span className="admin-note">{order.items?.length ?? 0} item{order.items?.length === 1 ? '' : 's'}</span></td>
                    <td><span className={`pill pill-${order.payment_status}`}>{order.payment_status}</span><span className="admin-note">{order.payment_method === 'cod' ? 'Cash on delivery' : 'Card'}</span></td>
                    <td>{STATUS_LABELS[order.status] ?? order.status}{order.store && <span className="admin-note" title={`Fulfilled by ${order.store.name}${order.store.city ? `, ${order.store.city}` : ''}`}>🏬 {order.store.name}</span>}{order.status === 'completed' && order.delivery_verified === true && <span className="admin-note" style={{ color: '#2f6d34' }} title={order.delivered_at ? `Confirmed ${new Date(order.delivered_at).toLocaleString()}` : ''}>✓ code verified</span>}{order.status === 'completed' && order.delivery_verified === false && <span className="admin-note" style={{ color: '#a23b28' }} title={order.delivery_note || ''}>⚠ delivered without code{order.delivery_note ? ` — ${order.delivery_note}` : ''}</span>}{order.rider_accepted_at && <span className="admin-note" style={{ color: '#2f6d34' }} title={`Accepted ${new Date(order.rider_accepted_at).toLocaleString()}`}>✓ accepted{order.delivery_partner?.name ? ` by ${order.delivery_partner.name}` : ''} · {new Date(order.rider_accepted_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>}{!order.rider_accepted_at && order.rider_offer_expires_at && <span className="admin-note" style={{ color: '#7a5c14' }} title={`Offer expires ${new Date(order.rider_offer_expires_at).toLocaleString()}`}>⏳ offered{order.delivery_partner?.name ? ` to ${order.delivery_partner.name}` : ''} (expires {new Date(order.rider_offer_expires_at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })})</span>}{order.rider_offer_decline_count > 0 && <span className="admin-note" style={{ color: '#a23b28' }} title="Riders who declined or missed this offer">↩ declined ×{order.rider_offer_decline_count}</span>}</td>
                    <td className="admin-courier">
                      {riders.length > 0 ? (
                        <>
                          <select value={order.delivery_partner_id ?? ''} disabled={busyId === order.id}
                            onChange={(event) => patchOrder(order, { delivery_partner_id: event.target.value ? Number(event.target.value) : null })}>
                            <option value="">— rider —</option>
                            {riders.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}
                          </select>
                          {order.courier_name && !order.delivery_partner_id && (
                            <span className="admin-note">manual: {order.courier_name}
                              <button type="button" className="link" disabled={busyId === order.id} onClick={() => patchOrder(order, { courier_name: null })}> clear</button>
                            </span>
                          )}
                        </>
                      ) : (
                        // No riders configured yet — fall back to a free-text courier name.
                        <>
                          <input value={courierDraft[order.id] ?? (order.courier_name ?? '')} placeholder="courier name"
                            onChange={(event) => setCourierDraft((current) => ({ ...current, [order.id]: event.target.value }))} />
                          <button type="button" disabled={busyId === order.id || courierDraft[order.id] === undefined} onClick={() => patchOrder(order, { courier_name: (courierDraft[order.id] ?? '').trim() || null })}>Save</button>
                        </>
                      )}
                    </td>
                    <td className="admin-actions">
                      {(() => {
                        const codCollect = order.payment_method === 'cod' && order.payment_status !== 'paid' && order.status !== 'cancelled'
                        const needsRefund = order.payment_status === 'refund_pending' || (order.payment_status === 'paid' && order.status === 'cancelled')
                        const refundedLink = order.payment_status === 'refunded' && order.stripe_dashboard_url
                        const steps = NEXT_ACTIONS[order.status] ?? []
                        if (!codCollect && !needsRefund && !refundedLink && steps.length === 0) {
                          const unpaid = order.status === 'pending_payment' || (order.payment_status !== 'paid' && order.status !== 'completed' && order.status !== 'cancelled')
                          return <span className="muted" title={unpaid ? "Nothing to do until the customer's payment goes through" : 'This order is finished'}>—</span>
                        }
                        return (
                          <>
                            {codCollect && (
                              <button type="button" disabled={busyId === order.id} className="act" onClick={() => patchOrder(order, { cash_collected: true })}>Mark cash collected</button>
                            )}
                            {needsRefund && (
                              order.stripe_payment_intent_id
                                ? <button type="button" disabled={busyId === order.id} className="act" onClick={() => refundOrder(order)}>Refund via Stripe</button>
                                : <button type="button" disabled={busyId === order.id} className="act" onClick={() => patchOrder(order, { refunded: true })}>Mark refunded</button>
                            )}
                            {refundedLink && (
                              <a className="act ghost" href={order.stripe_dashboard_url} target="_blank" rel="noreferrer">View in Stripe ↗</a>
                            )}
                            {steps.map(([status, label]) => (
                              <button key={status} type="button" disabled={busyId === order.id} className={status === 'cancelled' ? 'act danger' : 'act'} onClick={() => patchOrder(order, { status })}>{label}</button>
                            ))}
                          </>
                        )
                      })()}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          <Pager page={ordersMeta?.current_page ?? ordersPage} pageCount={ordersMeta?.last_page ?? 1} total={ordersMeta?.total ?? orders.length} onPage={setOrdersPage} pageSize={pageSize} onPageSize={setPageSize} />
        </section>
      )}

      {tab === 'products' && (
        <section className="admin-panel">
          <div className="admin-toolbar">
            <input className="admin-search" value={productSearch} placeholder="Search name or SKU" onChange={(event) => { setProductSearch(event.target.value); setProductsPage(1) }} />
            <label>Sort
              <select value={productSort} onChange={(event) => { setProductSort(event.target.value); setProductsPage(1) }}>
                <option value="newest">Newest first</option>
                <option value="oldest">Oldest first</option>
                <option value="name">Name (A–Z)</option>
                <option value="stock_low">Stock: low to high</option>
                <option value="stock_high">Stock: high to low</option>
              </select>
            </label>
            {stores.length > 0 && (
              <label>Store
                <select value={productStore} onChange={(event) => { setProductStore(event.target.value); setProductsPage(1) }}>
                  <option value="">All stores</option>
                  {stores.map((s) => <option key={s.id} value={s.id}>{s.name}{s.city ? ` — ${s.city}` : ''}</option>)}
                </select>
              </label>
            )}
            <button className="act" type="button" onClick={() => { if (!stores.length) loadStores(); setProductForm({ ...EMPTY_PRODUCT, category_id: categories[0]?.id ?? '' }) }}>New product</button>
          </div>

          {productForm && (
            <form className="admin-form" onSubmit={saveProduct}>
              <h3>{productForm.id ? `Edit product #${productForm.id}` : 'New product'}</h3>
              <div className="admin-form-grid">
                <label>Category
                  <select required value={productForm.category_id} onChange={(event) => setProductForm({ ...productForm, category_id: event.target.value })}>
                    <option value="" disabled>Choose…</option>
                    {categories.map((category) => <option key={category.id} value={category.id}>{category.name}</option>)}
                  </select>
                </label>
                <label>Name<input required value={productForm.name} onChange={(event) => setProductForm({ ...productForm, name: event.target.value })} /></label>
                <label>SKU<input required value={productForm.sku} onChange={(event) => setProductForm({ ...productForm, sku: event.target.value })} /></label>
                <label>Price (USD)<input required type="number" min="0" step="0.01" value={productForm.price} onChange={(event) => setProductForm({ ...productForm, price: event.target.value })} /></label>
                <label>Regular price ($)<input type="number" min="0" step="0.01" placeholder="pre-sale price; blank = not on sale" value={productForm.compare_at} onChange={(event) => setProductForm({ ...productForm, compare_at: event.target.value })} /></label>
                {productForm.per_store_stock
                  ? <label>Inventory<input type="text" value="Per store — see below" disabled title="This product tracks stock per store; the counts are in the Store stock section." /></label>
                  : <label>Inventory<input type="number" min="0" value={productForm.inventory_quantity} onChange={(event) => setProductForm({ ...productForm, inventory_quantity: event.target.value })} /></label>}
                <label className="admin-check"><input type="checkbox" checked={productForm.is_active} onChange={(event) => setProductForm({ ...productForm, is_active: event.target.checked })} /> Active</label>
              </div>
              <label>Image
                <div className="admin-image-field">
                  {productForm.image_url && <img src={mediaUrl(productForm.image_url)} alt="" className="admin-image-preview" onError={(event) => { event.currentTarget.style.display = 'none' }} />}
                  <input placeholder="Image URL, or upload →" value={productForm.image_url ?? ''} onChange={(event) => setProductForm({ ...productForm, image_url: event.target.value })} />
                  <input type="file" accept="image/*" disabled={imgBusy} onChange={(event) => uploadImage(event.target.files?.[0], (url) => setProductForm((form) => ({ ...form, image_url: url })))} />
                  {productForm.image_url && <button type="button" className="act ghost" onClick={() => setProductForm({ ...productForm, image_url: '' })}>Clear</button>}
                </div>
              </label>
              <label>Description<textarea rows="2" value={productForm.description ?? ''} onChange={(event) => setProductForm({ ...productForm, description: event.target.value })} /></label>

              <fieldset className="admin-fieldset">
                <legend>Options / variants</legend>
                <p className="muted">Leave empty for a single-price product. Add a row per variant &mdash; pack size, weight, colour, flavour, or a mix (e.g. &ldquo;1 kg&rdquo;, &ldquo;Red / Large&rdquo;). Each has its own price, compare-at price, stock, SKU and image.</p>
                {(productForm.variants ?? []).map((row, index) => row._delete ? null : (
                  <div className="admin-variant-row" key={row.id ?? `new-${index}`}>
                    <input placeholder="Label (1 kg, Red / Large…)" value={row.label} onChange={(event) => setProductForm({ ...productForm, variants: productForm.variants.map((r, i) => i === index ? { ...r, label: event.target.value } : r) })} />
                    <input placeholder="SKU" value={row.sku} onChange={(event) => setProductForm({ ...productForm, variants: productForm.variants.map((r, i) => i === index ? { ...r, sku: event.target.value } : r) })} />
                    <input type="number" min="0" step="0.01" placeholder="Price $" value={row.price} onChange={(event) => setProductForm({ ...productForm, variants: productForm.variants.map((r, i) => i === index ? { ...r, price: event.target.value } : r) })} />
                    <input type="number" min="0" step="0.01" placeholder="Reg. $" value={row.compare_at ?? ''} onChange={(event) => setProductForm({ ...productForm, variants: productForm.variants.map((r, i) => i === index ? { ...r, compare_at: event.target.value } : r) })} />
                    <input type="number" min="0" placeholder="Stock" value={row.stock} onChange={(event) => setProductForm({ ...productForm, variants: productForm.variants.map((r, i) => i === index ? { ...r, stock: event.target.value } : r) })} />
                    <span className="admin-variant-img">
                      <input placeholder="Image URL" value={row.image_url} onChange={(event) => setProductForm({ ...productForm, variants: productForm.variants.map((r, i) => i === index ? { ...r, image_url: event.target.value } : r) })} />
                      <input type="file" accept="image/*" disabled={imgBusy} onChange={(event) => uploadImage(event.target.files?.[0], (url) => setProductForm((form) => ({ ...form, variants: form.variants.map((r, i) => i === index ? { ...r, image_url: url } : r) })))} />
                    </span>
                    <label className="admin-check"><input type="checkbox" checked={row.is_active} onChange={(event) => setProductForm({ ...productForm, variants: productForm.variants.map((r, i) => i === index ? { ...r, is_active: event.target.checked } : r) })} /> On</label>
                    <button type="button" className="act danger" onClick={() => setProductForm({ ...productForm, variants: row.id
                      ? productForm.variants.map((r, i) => i === index ? { ...r, _delete: true } : r)
                      : productForm.variants.filter((_, i) => i !== index) })}>Remove</button>
                  </div>
                ))}
                <button type="button" className="act" onClick={() => setProductForm({ ...productForm, variants: [...(productForm.variants ?? []), { ...EMPTY_VARIANT }] })}>Add variant</button>
              </fieldset>

              <fieldset className="admin-fieldset">
                <legend>Store stock</legend>
                <label className="admin-check">
                  <input type="checkbox" checked={!!productForm.per_store_stock} onChange={(event) => setProductForm({ ...productForm, per_store_stock: event.target.checked })} />
                  Track stock per store
                </label>
                {!productForm.per_store_stock
                  ? (stores.length >= 2
                    ? <p className="muted">You have <strong>{stores.length} stores</strong> — they can&rsquo;t share one inventory number. <button type="button" className="act" onClick={() => setProductForm({ ...productForm, per_store_stock: true })}>Give each store its own count</button></p>
                    : <p className="muted">Off — the single <strong>Inventory</strong> / variant <strong>Stock</strong> above applies at every store. Turn on for a multi-store shop so each store has its own count and out-of-stock state.</p>)
                  : stores.length === 0
                    ? <p className="muted">No stores yet — add them under <strong>Stores</strong> first.</p>
                    : <>
                        <p className="muted">Untick <em>Carried</em> for a store that doesn&rsquo;t sell this at all (it disappears there). Quantity 0 keeps it listed as &ldquo;out of stock&rdquo;.</p>
                        <div className="admin-scroll-x">
                          <table className="admin-stock-grid">
                            <thead><tr><th>Store</th><th>Carried</th><th>Qty</th>
                              {(productForm.variants ?? []).filter((v) => !v._delete).map((v, i) => <th key={i}>{v.label || v.sku || `Variant ${i + 1}`}</th>)}
                            </tr></thead>
                            <tbody>
                              {stores.map((store) => {
                                // Pre-fill a store's count from the product's single Inventory
                                // value until it's edited, so the grid isn't all blanks.
                                const row = productForm.store_stock?.[store.id] ?? { is_stocked: true, base: String(productForm.inventory_quantity ?? ''), variants: {} }
                                const setRow = (patch) => setProductForm((form) => ({ ...form, store_stock: { ...form.store_stock, [store.id]: { ...row, ...patch } } }))
                                return (
                                  <tr key={store.id}>
                                    <td>{store.name || `#${store.id}`}{store.city ? ` — ${store.city}` : ''}</td>
                                    <td><input type="checkbox" checked={row.is_stocked !== false} onChange={(event) => setRow({ is_stocked: event.target.checked })} /></td>
                                    <td><input type="number" min="0" value={row.base ?? ''} disabled={row.is_stocked === false} onChange={(event) => setRow({ base: event.target.value })} /></td>
                                    {(productForm.variants ?? []).map((v, i) => v._delete ? null : (
                                      <td key={i}><input type="number" min="0" value={row.variants?.[i] ?? ''} disabled={row.is_stocked === false} onChange={(event) => setRow({ variants: { ...row.variants, [i]: event.target.value } })} /></td>
                                    ))}
                                  </tr>
                                )
                              })}
                            </tbody>
                          </table>
                        </div>
                      </>}
              </fieldset>

              <div className="admin-form-actions">
                <button className="act" type="submit">Save</button>
                <button className="act ghost" type="button" onClick={() => setProductForm(null)}>Cancel</button>
              </div>
            </form>
          )}

          {listBusy.products && products.length === 0 ? <p className="admin-empty">Loading products…</p> : products.length === 0 ? <p className="admin-empty">No products.</p> : (
            <table className="admin-table">
              <thead><tr><th>Name</th><th>SKU</th><th>Category</th><th>Price</th><th>Stock</th><th>Variants</th><th>Active</th><th></th></tr></thead>
              <tbody>
                {products.map((product) => {
                  const packs = (product.variants ?? []).filter((v) => v.is_active).length
                  return (
                  <tr key={product.id}>
                    <td>{product.name}</td>
                    <td>{product.sku}</td>
                    <td>{product.category?.name ?? '—'}</td>
                    <td>{packs ? `${money(Math.min(...product.variants.filter((v) => v.is_active).map((v) => v.price_cents)))}+` : <>{money(product.price_cents)}{product.compare_at_price_cents > product.price_cents && <s className="muted" style={{ marginLeft: 5 }}>{money(product.compare_at_price_cents)}</s>}</>}</td>
                    <td className={(product.effective_stock ?? product.inventory_quantity) <= 5 ? 'low' : ''}>{packs ? '—' : (product.effective_stock ?? product.inventory_quantity)}{productStore && !packs ? <span className="admin-note">at {stores.find((s) => String(s.id) === String(productStore))?.name ?? 'store'}</span> : null}</td>
                    <td>{packs || '—'}</td>
                    <td>{product.is_active ? 'Yes' : 'No'}</td>
                    <td className="admin-actions">
                      <button className="act" type="button" onClick={() => { if (!stores.length) loadStores(); setProductForm({ id: product.id, category_id: product.category_id, name: product.name, sku: product.sku, price: (product.price_cents / 100).toFixed(2), compare_at: dollarsOrBlank(product.compare_at_price_cents), inventory_quantity: product.inventory_quantity, description: product.description ?? '', image_url: product.image_url ?? '', is_active: product.is_active, per_store_stock: (product.store_inventory ?? []).length > 0, store_stock: storeStockFrom(product), variants: variantRowsFrom(product) }) }}>Edit</button>
                      <button className="act danger" type="button" onClick={() => removeProduct(product)}>Delete</button>
                    </td>
                  </tr>
                )})}
              </tbody>
            </table>
          )}
          <Pager page={productsMeta?.current_page ?? productsPage} pageCount={productsMeta?.last_page ?? 1} total={productsMeta?.total ?? products.length} onPage={setProductsPage} pageSize={pageSize} onPageSize={setPageSize} />
        </section>
      )}

      {tab === 'categories' && (
        <section className="admin-panel">
          <div className="admin-toolbar">
            <button className="act" type="button" onClick={() => setCategoryForm({ ...EMPTY_CATEGORY })}>New category</button>
          </div>

          {categoryForm && (
            <form className="admin-form" onSubmit={saveCategory}>
              <h3>{categoryForm.id ? `Edit category #${categoryForm.id}` : 'New category'}</h3>
              <div className="admin-form-grid">
                <label>Name<input required value={categoryForm.name} onChange={(event) => setCategoryForm({ ...categoryForm, name: event.target.value })} /></label>
                <label>Slug (optional)<input value={categoryForm.slug ?? ''} onChange={(event) => setCategoryForm({ ...categoryForm, slug: event.target.value })} /></label>
                <label>Sort order<input type="number" min="0" value={categoryForm.sort_order} onChange={(event) => setCategoryForm({ ...categoryForm, sort_order: event.target.value })} /></label>
                <label className="admin-check"><input type="checkbox" checked={categoryForm.is_active} onChange={(event) => setCategoryForm({ ...categoryForm, is_active: event.target.checked })} /> Active</label>
              </div>
              <div className="admin-form-actions">
                <button className="act" type="submit">Save</button>
                <button className="act ghost" type="button" onClick={() => setCategoryForm(null)}>Cancel</button>
              </div>
            </form>
          )}

          {listBusy.categories && categories.length === 0 ? <p className="admin-empty">Loading categories…</p> : categories.length === 0 ? <p className="admin-empty">No categories.</p> : (
            <table className="admin-table">
              <thead><tr><th>Name</th><th>Slug</th><th>Products</th><th>Sort</th><th>Active</th><th></th></tr></thead>
              <tbody>
                {pageSlice(categories, categoriesPage).map((category) => (
                  <tr key={category.id}>
                    <td>{category.name}</td>
                    <td>{category.slug}</td>
                    <td>{category.products_count ?? 0}</td>
                    <td>{category.sort_order}</td>
                    <td>{category.is_active ? 'Yes' : 'No'}</td>
                    <td className="admin-actions">
                      <button className="act" type="button" onClick={() => setCategoryForm({ id: category.id, name: category.name, slug: category.slug, sort_order: category.sort_order, is_active: category.is_active })}>Edit</button>
                      <button className="act danger" type="button" onClick={() => removeCategory(category)}>Delete</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          <Pager page={categoriesPage} pageCount={Math.max(1, Math.ceil(categories.length / pageSize))} total={categories.length} onPage={setCategoriesPage} pageSize={pageSize} onPageSize={setPageSize} />
        </section>
      )}

      {tab === 'customers' && (
        <section className="admin-panel">
          {listBusy.customers && customers.length === 0 ? <p className="admin-empty">Loading customers…</p> : customers.length === 0 ? <p className="admin-empty">No customers yet.</p> : (
            <table className="admin-table">
              <thead><tr><th>Name</th><th>Email</th><th>Orders</th><th>Paid spend</th><th>Joined</th><th></th></tr></thead>
              <tbody>
                {customers.map((customer) => (
                  <tr key={customer.id}>
                    <td>{customer.name}</td>
                    <td>{customer.email}</td>
                    <td>{customer.orders_count}</td>
                    <td>{money(customer.spent_cents)}</td>
                    <td>{new Date(customer.joined_at).toLocaleDateString()}</td>
                    <td className="admin-actions"><button className="act" type="button" onClick={() => openCustomer(customer.id)}>View</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          <Pager page={customersMeta?.current_page ?? customersPage} pageCount={customersMeta?.last_page ?? 1} total={customersMeta?.total ?? customers.length} onPage={setCustomersPage} pageSize={pageSize} onPageSize={setPageSize} />
        </section>
      )}

      {tab === 'riders' && (
        <section className="admin-panel">
          <form className="admin-toolbar" onSubmit={addRider}>
            <input type="email" placeholder="rider@example.com" value={riderEmail} onChange={(event) => setRiderEmail(event.target.value)} />
            <button className="act" type="submit">Add rider</button>
            <span className="muted">Turns an existing customer account into a delivery rider. Auto-assign picks the nearest on-shift rider linked to the order&rsquo;s store; unassigned orders fall back to the pickup pool.</span>
          </form>

          {riderForm && (
            <form className="admin-form" onSubmit={saveRider}>
              <h3>{riderForm.name}</h3>
              <div className="admin-form-grid">
                <label>Phone<input value={riderForm.phone} placeholder="e.g. +1 555 987 6543" onChange={(event) => setRiderForm({ ...riderForm, phone: event.target.value })} /></label>
                <label>Full day (hours)<input type="number" step="0.5" min="0.5" max="24" value={riderForm.daily_target_hours} placeholder="8" onChange={(event) => setRiderForm({ ...riderForm, daily_target_hours: event.target.value })} /></label>
                <label className="admin-check"><input type="checkbox" checked={riderForm.rider_is_active} onChange={(event) => setRiderForm({ ...riderForm, rider_is_active: event.target.checked })} /> On shift (available for auto-assign)</label>
              </div>

              <fieldset className="admin-fieldset">
                <legend>Stores served</legend>
                <p className="muted">A rider only gets orders (auto-assigned or from the pool) for the stores ticked here. Tick more than one for nearby cities.</p>
                {stores.length === 0
                  ? <p className="muted">No stores yet — add them under <strong>Stores</strong> first.</p>
                  : <div className="admin-check-list">
                      {stores.map((store) => {
                        const picked = riderForm.store_ids.includes(store.id)
                        return (
                          <label className="admin-check" key={store.id}>
                            <input type="checkbox" checked={picked} onChange={(event) => setRiderForm((form) => ({
                              ...form,
                              store_ids: event.target.checked
                                ? [...form.store_ids, store.id]
                                : form.store_ids.filter((id) => id !== store.id),
                            }))} />
                            {store.name || `Store #${store.id}`}{store.city ? ` — ${store.city}` : ''}
                          </label>
                        )
                      })}
                    </div>}
              </fieldset>

              <fieldset className="admin-fieldset">
                <legend>Home base</legend>
                <p className="muted">Where auto-assign measures from when the rider app has no recent live location. Type an address (geocoded on save) or drag the pin.</p>
                <div className="admin-form-grid">
                  <label>Base address<input value={riderForm.rider_base_address} onChange={(event) => setRiderForm({ ...riderForm, rider_base_address: event.target.value })} /></label>
                  <label>Latitude<input type="number" step="any" value={riderForm.rider_base_lat} onChange={(event) => setRiderForm({ ...riderForm, rider_base_lat: event.target.value })} /></label>
                  <label>Longitude<input type="number" step="any" value={riderForm.rider_base_lng} onChange={(event) => setRiderForm({ ...riderForm, rider_base_lng: event.target.value })} /></label>
                </div>
                <MapPicker
                  lat={riderForm.rider_base_lat === '' ? NaN : Number(riderForm.rider_base_lat)}
                  lng={riderForm.rider_base_lng === '' ? NaN : Number(riderForm.rider_base_lng)}
                  onPick={(la, ln) => setRiderForm((form) => ({ ...form, rider_base_lat: la.toFixed(6), rider_base_lng: ln.toFixed(6) }))}
                />
              </fieldset>

              <div className="admin-form-actions">
                <button className="act" type="submit">Save</button>
                <button className="act ghost" type="button" onClick={() => setRiderForm(null)}>Cancel</button>
              </div>
            </form>
          )}

          {listBusy.riders && riders.length === 0 ? <p className="admin-empty">Loading riders…</p> : riders.length === 0 ? <p className="admin-empty">No riders yet. Add one by email above.</p> : (
            <table className="admin-table">
              <thead><tr><th>Name</th><th>Phone</th><th>Status</th><th>Stores</th><th>Location</th><th>Rating</th><th>Active jobs</th><th>On shift</th><th></th></tr></thead>
              <tbody>
                {pageSlice(riders, ridersPage).map((rider) => (
                  <tr key={rider.id}>
                    <td>{rider.name}<span className="admin-note">{rider.email}</span></td>
                    <td>{rider.phone || <span className="muted">—</span>}</td>
                    <td>{riderStatusChip(rider)}</td>
                    <td>{(rider.stores ?? []).length
                      ? (rider.stores).map((s) => s.name).join(', ')
                      : <span className="muted">none — can&rsquo;t be auto-assigned</span>}</td>
                    <td>{rider.located
                      ? <span title={rider.located.last_ping_at ? `pinged ${new Date(rider.located.last_ping_at).toLocaleString()}` : ''}>{rider.located.source === 'live' ? '🟢 live' : '📍 base'}</span>
                      : <span className="muted">no base set</span>}</td>
                    <td><button className="act ghost" type="button" onClick={() => openRiderDetail(rider.id, 'reviews')}>{rider.rating_count ? `★ ${(rider.rating_avg ?? 0).toFixed(1)} (${rider.rating_count})` : 'Reviews'}</button></td>
                    <td className={rider.active_deliveries > 0 ? 'low' : ''}>{rider.active_deliveries}</td>
                    <td>{rider.rider_is_active ? 'Yes' : 'No'}</td>
                    <td className="admin-actions">
                      <button className="act" type="button" onClick={() => openRiderDetail(rider.id)}>Attendance &amp; stats</button>
                      <button className="act" type="button" onClick={() => setRiderForm(riderFormFrom(rider))}>Edit</button>
                      {rider.attendance?.available
                        ? <button className="act" type="button" onClick={() => { const why = window.prompt('Reason for taking this rider offline (optional):', ''); if (why !== null) patchRider(rider, { rider_available: false, rider_unavailable_reason: why || null }) }}>Set offline</button>
                        : rider.attendance?.clocked_in && <button className="act" type="button" onClick={() => patchRider(rider, { rider_available: true })}>Bring online</button>}
                      <button className="act danger" type="button" onClick={() => removeRider(rider)}>Remove</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          <Pager page={ridersPage} pageCount={Math.max(1, Math.ceil(riders.length / pageSize))} total={riders.length} onPage={setRidersPage} pageSize={pageSize} onPageSize={setPageSize} />
        </section>
      )}

      {tab === 'stores' && (
        <section className="admin-panel">
          <div className="admin-toolbar">
            <button className="act" type="button" onClick={() => setStoreForm({ ...EMPTY_STORE })}>New store</button>
            <span className="muted">Customers outside every active store&rsquo;s radius can browse but can&rsquo;t check out.</span>
          </div>

          {storeForm && (
            <form className="admin-form" onSubmit={saveStore}>
              <h3>{storeForm.id ? `Edit store #${storeForm.id}` : 'New store'}</h3>
              <div className="admin-form-grid">
                <label>Name<input value={storeForm.name} placeholder="Main Store" onChange={(event) => setStoreForm({ ...storeForm, name: event.target.value })} /></label>
                <label>Street<input required value={storeForm.line1} onChange={(event) => setStoreForm({ ...storeForm, line1: event.target.value })} /></label>
                <label>Line 2<input value={storeForm.line2 ?? ''} onChange={(event) => setStoreForm({ ...storeForm, line2: event.target.value })} /></label>
                <label>City<input required value={storeForm.city} onChange={(event) => setStoreForm({ ...storeForm, city: event.target.value })} /></label>
                <label>State<input required maxLength="60" value={storeForm.state} onChange={(event) => setStoreForm({ ...storeForm, state: event.target.value })} /></label>
                <label>Postal code<input required maxLength="12" value={storeForm.postal_code} onChange={(event) => setStoreForm({ ...storeForm, postal_code: event.target.value })} /></label>
                <label>Delivery radius (km)<input required type="number" min="1" max="200" value={storeForm.delivery_radius_km} onChange={(event) => setStoreForm({ ...storeForm, delivery_radius_km: event.target.value })} /></label>
                <label>Latitude (optional)<input type="number" step="any" value={storeForm.latitude ?? ''} onChange={(event) => setStoreForm({ ...storeForm, latitude: event.target.value })} /></label>
                <label>Longitude (optional)<input type="number" step="any" value={storeForm.longitude ?? ''} onChange={(event) => setStoreForm({ ...storeForm, longitude: event.target.value })} /></label>
                <label className="admin-check"><input type="checkbox" checked={storeForm.is_active} onChange={(event) => setStoreForm({ ...storeForm, is_active: event.target.checked })} /> Active</label>
              </div>
              <p className="muted">Type an address (geocoded on save) or drag the pin to set the exact spot. The pin fills latitude/longitude.</p>
              <MapPicker
                lat={storeForm.latitude === '' ? NaN : Number(storeForm.latitude)}
                lng={storeForm.longitude === '' ? NaN : Number(storeForm.longitude)}
                onPick={(la, ln) => setStoreForm((form) => ({ ...form, latitude: la.toFixed(6), longitude: ln.toFixed(6) }))}
              />
              <p className="muted">{storeForm.latitude !== '' && Number.isFinite(Number(storeForm.latitude)) ? `Pin: ${Number(storeForm.latitude).toFixed(5)}, ${Number(storeForm.longitude).toFixed(5)}` : 'No pin set yet — drag the marker or save with an address to locate it.'}</p>
              <div className="admin-form-actions">
                <button className="act" type="submit">Save</button>
                <button className="act ghost" type="button" onClick={() => setStoreForm(null)}>Cancel</button>
              </div>
            </form>
          )}

          {listBusy.stores && stores.length === 0 ? <p className="admin-empty">Loading stores…</p> : stores.length === 0 ? <p className="admin-empty">No stores yet. Add one to switch on delivery-area checks.</p> : (
            <table className="admin-table">
              <thead><tr><th>Name</th><th>Address</th><th>Radius</th><th>Location</th><th>Active</th><th></th></tr></thead>
              <tbody>
                {pageSlice(stores, storesPage).map((store) => (
                  <tr key={store.id}>
                    <td>{store.name}</td>
                    <td>{[store.line1, store.city, store.state, store.postal_code].filter(Boolean).join(', ')}</td>
                    <td>{store.delivery_radius_km} km</td>
                    <td>{store.latitude != null && store.longitude != null
                      ? `${Number(store.latitude).toFixed(4)}, ${Number(store.longitude).toFixed(4)}`
                      : <span className="muted">not located — add coordinates</span>}</td>
                    <td>{store.is_active ? 'Yes' : 'No'}</td>
                    <td className="admin-actions">
                      <button className="act" type="button" onClick={() => setStoreForm({ id: store.id, name: store.name ?? '', line1: store.line1 ?? '', line2: store.line2 ?? '', city: store.city ?? '', state: store.state ?? '', postal_code: store.postal_code ?? '', latitude: store.latitude ?? '', longitude: store.longitude ?? '', delivery_radius_km: store.delivery_radius_km ?? 5, is_active: store.is_active })}>Edit</button>
                      <button className="act danger" type="button" onClick={() => removeStore(store)}>Delete</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
          <Pager page={storesPage} pageCount={Math.max(1, Math.ceil(stores.length / pageSize))} total={stores.length} onPage={setStoresPage} pageSize={pageSize} onPageSize={setPageSize} />
        </section>
      )}

      {tab === 'homepage' && (
        <section className="admin-panel">
          <h3 className="admin-subhead">Promo banners</h3>
          <div className="admin-toolbar">
            <button className="act" type="button" onClick={() => setBannerForm({ ...EMPTY_BANNER })}>New banner</button>
            <span className="muted">Set each banner&rsquo;s <strong>Placement</strong>: <strong>Hero</strong> = full-width image at the top, <strong>Strip</strong> = the 3-up row below. Add as many as you like with &ldquo;New banner&rdquo;; &ldquo;Order&rdquo; sorts them within each row.</span>
          </div>

          {bannerForm && (
            <form className="admin-form" onSubmit={saveBanner}>
              <h3>{bannerForm.id ? `Edit banner #${bannerForm.id}` : 'New banner'}</h3>
              <div className="admin-image-field">
                {bannerForm.image_url
                  ? <img className="admin-banner-preview" src={mediaUrl(bannerForm.image_url)} alt="" />
                  : <div className="admin-banner-preview placeholder">No image</div>}
                <div>
                  <label>Image URL<input value={bannerForm.image_url} onChange={(event) => setBannerForm({ ...bannerForm, image_url: event.target.value })} placeholder="https://…" /></label>
                  <input type="file" accept="image/*" disabled={imgBusy} onChange={(event) => uploadImage(event.target.files?.[0], (url) => setBannerForm((form) => ({ ...form, image_url: url })))} />
                  {imgBusy && <span className="muted"> uploading…</span>}
                </div>
              </div>
              <div className="admin-form-grid">
                <label>Headline (optional)<input maxLength="120" value={bannerForm.headline} onChange={(event) => setBannerForm({ ...bannerForm, headline: event.target.value })} placeholder="Fresh fruits & veg, in minutes" /></label>
                <label>Links to category<select value={bannerForm.category_slug} onChange={(event) => setBannerForm({ ...bannerForm, category_slug: event.target.value })}><option value="">— none —</option>{categories.map((c) => <option key={c.id} value={c.slug}>{c.name}</option>)}</select></label>
                <label>Or link URL<input value={bannerForm.link_url} onChange={(event) => setBannerForm({ ...bannerForm, link_url: event.target.value })} placeholder="https://… (used only if no category)" /></label>
                <label>Placement<select value={bannerForm.placement} onChange={(event) => setBannerForm({ ...bannerForm, placement: event.target.value })}><option value="hero">Hero — full-width top</option><option value="strip">Strip — 3-up row</option></select></label>
                <label>Sort order<input type="number" min="0" max="9999" value={bannerForm.sort_order} onChange={(event) => setBannerForm({ ...bannerForm, sort_order: event.target.value })} /></label>
                <label className="admin-check"><input type="checkbox" checked={bannerForm.is_active} onChange={(event) => setBannerForm({ ...bannerForm, is_active: event.target.checked })} /> Active</label>
              </div>
              <div className="admin-form-actions">
                <button className="act" type="submit" disabled={!bannerForm.image_url}>Save</button>
                <button className="act ghost" type="button" onClick={() => setBannerForm(null)}>Cancel</button>
              </div>
            </form>
          )}

          {banners.length === 0 ? <p className="admin-empty">No banners yet. Add one to fill the homepage promo area.</p> : (
            <table className="admin-table">
              <thead><tr><th>Preview</th><th>Headline</th><th>Placement</th><th>Target</th><th>Order</th><th>Active</th><th></th></tr></thead>
              <tbody>
                {banners.map((banner) => (
                  <tr key={banner.id}>
                    <td><img className="admin-banner-thumb" src={mediaUrl(banner.image_url)} alt="" /></td>
                    <td>{banner.headline || <span className="muted">—</span>}</td>
                    <td>{banner.placement === 'strip' ? 'Strip' : 'Hero'}</td>
                    <td>{banner.category_slug ? `#${banner.category_slug}` : (banner.link_url || <span className="muted">—</span>)}</td>
                    <td>{banner.sort_order}</td>
                    <td>{banner.is_active ? 'Yes' : 'No'}</td>
                    <td className="admin-actions">
                      <button className="act" type="button" onClick={() => setBannerForm({ id: banner.id, image_url: banner.image_url ?? '', headline: banner.headline ?? '', category_slug: banner.category_slug ?? '', link_url: banner.link_url ?? '', placement: banner.placement ?? 'strip', sort_order: banner.sort_order ?? 0, is_active: banner.is_active })}>Edit</button>
                      <button className="act danger" type="button" onClick={() => removeBanner(banner)}>Delete</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}

          <h3 className="admin-subhead">Category tiles</h3>
          <div className="admin-toolbar">
            <button className="act" type="button" onClick={() => setTileForm({ ...EMPTY_TILE })}>New tile</button>
            <span className="muted">The homepage shows these in order — first three as large cards, the rest as a grid. Leave the title or image blank to use the category&rsquo;s own. With no active tiles the homepage lists every category.</span>
          </div>

          {tileForm && (
            <form className="admin-form" onSubmit={saveTile}>
              <h3>{tileForm.id ? `Edit tile #${tileForm.id}` : 'New tile'}</h3>
              <div className="admin-image-field">
                {tileForm.image_url
                  ? <img className="admin-banner-thumb" src={mediaUrl(tileForm.image_url)} alt="" />
                  : <div className="admin-banner-thumb placeholder">category image</div>}
                <div>
                  <label>Custom image URL (optional)<input value={tileForm.image_url} onChange={(event) => setTileForm({ ...tileForm, image_url: event.target.value })} placeholder="blank = use the category image" /></label>
                  <input type="file" accept="image/*" disabled={imgBusy} onChange={(event) => uploadImage(event.target.files?.[0], (url) => setTileForm((form) => ({ ...form, image_url: url })))} />
                  {imgBusy && <span className="muted"> uploading…</span>}
                </div>
              </div>
              <div className="admin-form-grid">
                <label>Category<select value={tileForm.category_slug} onChange={(event) => setTileForm({ ...tileForm, category_slug: event.target.value })}><option value="">— none (use link) —</option>{categories.map((c) => <option key={c.id} value={c.slug}>{c.name}</option>)}</select></label>
                <label>Custom title (optional)<input maxLength="120" value={tileForm.title} onChange={(event) => setTileForm({ ...tileForm, title: event.target.value })} placeholder="blank = category name" /></label>
                <label>Or link URL<input value={tileForm.link_url} onChange={(event) => setTileForm({ ...tileForm, link_url: event.target.value })} placeholder="used only if no category" /></label>
                <label>Sort order<input type="number" min="0" max="9999" value={tileForm.sort_order} onChange={(event) => setTileForm({ ...tileForm, sort_order: event.target.value })} /></label>
                <label className="admin-check"><input type="checkbox" checked={tileForm.is_active} onChange={(event) => setTileForm({ ...tileForm, is_active: event.target.checked })} /> Active</label>
              </div>
              <div className="admin-form-actions">
                <button className="act" type="submit" disabled={!tileForm.category_slug && !tileForm.link_url.trim()}>Save</button>
                <button className="act ghost" type="button" onClick={() => setTileForm(null)}>Cancel</button>
              </div>
            </form>
          )}

          {homeTiles.length === 0 ? <p className="admin-empty">No tiles — the homepage is listing every category.</p> : (
            <table className="admin-table">
              <thead><tr><th>Image</th><th>Title</th><th>Target</th><th>Order</th><th>Active</th><th></th></tr></thead>
              <tbody>
                {homeTiles.map((tile) => (
                  <tr key={tile.id}>
                    <td>{tile.image_url ? <img className="admin-banner-thumb" src={mediaUrl(tile.image_url)} alt="" /> : <span className="muted">category</span>}</td>
                    <td>{tile.title || <span className="muted">category name</span>}</td>
                    <td>{tile.category_slug ? `#${tile.category_slug}` : (tile.link_url || <span className="muted">—</span>)}</td>
                    <td>{tile.sort_order}</td>
                    <td>{tile.is_active ? 'Yes' : 'No'}</td>
                    <td className="admin-actions">
                      <button className="act" type="button" onClick={() => setTileForm({ id: tile.id, title: tile.title ?? '', image_url: tile.image_url ?? '', category_slug: tile.category_slug ?? '', link_url: tile.link_url ?? '', sort_order: tile.sort_order ?? 0, is_active: tile.is_active })}>Edit</button>
                      <button className="act danger" type="button" onClick={() => removeTile(tile)}>Delete</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      )}

      {tab === 'pages' && (
        <section className="admin-panel">
          <div className="admin-toolbar">
            <button className="act" type="button" onClick={() => newPage()}>New page</button>
            <span className="muted">Content pages linked from the storefront footer. Content is Markdown (## heading, **bold**, - list, [text](url)).</span>
          </div>

          {pageForm && (
            <form className="admin-form" onSubmit={savePage}>
              <h3>{pageForm.id ? `Edit “${pageForm.title || 'page'}”` : 'New page'}</h3>
              <div className="admin-form-grid">
                <label>Title<input required maxLength="160" value={pageForm.title} onChange={(event) => setPageForm({ ...pageForm, title: event.target.value })} /></label>
                <label>Slug (optional)<input value={pageForm.slug} placeholder="auto from title" onChange={(event) => setPageForm({ ...pageForm, slug: event.target.value })} /></label>
                <label>Footer group<input value={pageForm.footer_group} onChange={(event) => setPageForm({ ...pageForm, footer_group: event.target.value })} /></label>
                <label>Sort order<input type="number" min="0" max="9999" value={pageForm.sort_order} onChange={(event) => setPageForm({ ...pageForm, sort_order: event.target.value })} /></label>
                <label>Banner image URL<input value={pageForm.banner_image ?? ''} placeholder="/img/… or https://… — shown above the title" onChange={(event) => setPageForm({ ...pageForm, banner_image: event.target.value })} /></label>
                <label className="admin-check"><input type="checkbox" checked={pageForm.show_in_footer} onChange={(event) => setPageForm({ ...pageForm, show_in_footer: event.target.checked })} /> Show in footer</label>
                <label className="admin-check"><input type="checkbox" checked={pageForm.is_published} onChange={(event) => setPageForm({ ...pageForm, is_published: event.target.checked })} /> Published</label>
              </div>
              <div className="admin-sections">
                <div className="admin-subhead" style={{ marginTop: 4 }}>Sections</div>
                {(pageForm.sections ?? []).length === 0
                  ? <p className="muted">No sections yet — the page shows the body text below. Add sections for a richer layout; preview on the storefront at <code>/#/p/{pageForm.slug || 'slug'}</code>.</p>
                  : null}
                {(pageForm.sections ?? []).map((s, i) => (
                  <div className="admin-section-card" key={i}>
                    <div className="admin-section-head">
                      <strong>{i + 1}. {sectionLabel(s.type)}</strong>
                      <div className="admin-section-tools">
                        <button type="button" className="act ghost" disabled={i === 0} onClick={() => moveSection(i, -1)}>&uarr;</button>
                        <button type="button" className="act ghost" disabled={i === pageForm.sections.length - 1} onClick={() => moveSection(i, 1)}>&darr;</button>
                        <button type="button" className="act danger" onClick={() => removeSection(i)}>Remove</button>
                      </div>
                    </div>
                    {s.type === 'rich_text' && (
                      <label>Markdown<textarea rows="6" value={s.markdown ?? ''} onChange={(event) => patchSection(i, { markdown: event.target.value })} /></label>
                    )}
                    {(s.type === 'hero' || s.type === 'cta') && (
                      <>
                        {s.type === 'hero' && <label>Image URL<input value={s.image_url ?? ''} onChange={(event) => patchSection(i, { image_url: event.target.value })} placeholder="/img/… or https://…" /></label>}
                        <label>Heading<input value={s.heading ?? ''} onChange={(event) => patchSection(i, { heading: event.target.value })} /></label>
                        <label>Text<textarea rows="2" value={s.text ?? ''} onChange={(event) => patchSection(i, { text: event.target.value })} /></label>
                        <div className="admin-form-grid">
                          <label>Button label<input value={s.button_label ?? ''} onChange={(event) => patchSection(i, { button_label: event.target.value })} /></label>
                          <label>Button URL<input value={s.button_url ?? ''} onChange={(event) => patchSection(i, { button_url: event.target.value })} placeholder="https://… or /#/p/…" /></label>
                        </div>
                      </>
                    )}
                    {s.type === 'media_text' && (
                      <>
                        <div className="admin-form-grid">
                          <label>Image URL<input value={s.image_url ?? ''} onChange={(event) => patchSection(i, { image_url: event.target.value })} /></label>
                          <label>Image side<select value={s.image_side ?? 'left'} onChange={(event) => patchSection(i, { image_side: event.target.value })}><option value="left">Left</option><option value="right">Right</option></select></label>
                        </div>
                        <label>Heading<input value={s.heading ?? ''} onChange={(event) => patchSection(i, { heading: event.target.value })} /></label>
                        <label>Text (Markdown)<textarea rows="5" value={s.markdown ?? ''} onChange={(event) => patchSection(i, { markdown: event.target.value })} /></label>
                      </>
                    )}
                    {s.type === 'feature_grid' && (
                      <>
                        <label>Heading<input value={s.heading ?? ''} onChange={(event) => patchSection(i, { heading: event.target.value })} /></label>
                        {(s.items ?? []).map((it, ii) => (
                          <div className="admin-feature-row admin-feature-row--quad" key={ii}>
                            <input placeholder="Icon / image URL" value={it.image_url ?? ''} onChange={(event) => patchItem(i, ii, { image_url: event.target.value })} />
                            <input placeholder="Title" value={it.title ?? ''} onChange={(event) => patchItem(i, ii, { title: event.target.value })} />
                            <input placeholder="Text" value={it.text ?? ''} onChange={(event) => patchItem(i, ii, { text: event.target.value })} />
                            <input placeholder="Link URL (optional)" value={it.link_url ?? ''} onChange={(event) => patchItem(i, ii, { link_url: event.target.value })} />
                            <button type="button" className="act danger" onClick={() => removeItem(i, ii)}>&times;</button>
                          </div>
                        ))}
                        <button type="button" className="act ghost" onClick={() => addItem(i)}>+ Card</button>
                      </>
                    )}
                    {(s.type === 'stats' || s.type === 'steps') && (
                      <>
                        <label>Heading<input value={s.heading ?? ''} onChange={(event) => patchSection(i, { heading: event.target.value })} /></label>
                        {(s.items ?? []).map((it, ii) => (
                          <div className="admin-feature-row admin-feature-row--pair" key={ii}>
                            <input placeholder={s.type === 'stats' ? 'Value (e.g. 10 min)' : 'Step title'} value={it.title ?? ''} onChange={(event) => patchItem(i, ii, { title: event.target.value })} />
                            <input placeholder={s.type === 'stats' ? 'Caption' : 'Step description'} value={it.text ?? ''} onChange={(event) => patchItem(i, ii, { text: event.target.value })} />
                            <button type="button" className="act danger" onClick={() => removeItem(i, ii)}>&times;</button>
                          </div>
                        ))}
                        <button type="button" className="act ghost" onClick={() => addItem(i)}>+ {s.type === 'stats' ? 'Stat' : 'Step'}</button>
                      </>
                    )}
                    {s.type === 'faq' && (
                      <>
                        <label>Heading<input value={s.heading ?? ''} onChange={(event) => patchSection(i, { heading: event.target.value })} /></label>
                        {(s.items ?? []).map((it, ii) => (
                          <div className="admin-faq-row" key={ii}>
                            <input placeholder="Question" value={it.title ?? ''} onChange={(event) => patchItem(i, ii, { title: event.target.value })} />
                            <textarea rows="2" placeholder="Answer (Markdown allowed)" value={it.text ?? ''} onChange={(event) => patchItem(i, ii, { text: event.target.value })} />
                            <button type="button" className="act danger" onClick={() => removeItem(i, ii)}>Remove</button>
                          </div>
                        ))}
                        <button type="button" className="act ghost" onClick={() => addItem(i)}>+ Question</button>
                      </>
                    )}
                    {s.type === 'quote' && (
                      <>
                        <label>Quote<textarea rows="3" value={s.text ?? ''} onChange={(event) => patchSection(i, { text: event.target.value })} /></label>
                        <label>Attribution<input value={s.author ?? ''} onChange={(event) => patchSection(i, { author: event.target.value })} placeholder="Name, role" /></label>
                      </>
                    )}
                  </div>
                ))}
                <div className="admin-section-add">
                  {SECTION_TYPES.map(([type, label]) => (
                    <button key={type} type="button" className="act" onClick={() => addSection(type)}>+ {label}</button>
                  ))}
                </div>
              </div>

              <label>Page body (Markdown) — shown when the page has no sections
                <div className="admin-page-editor">
                  <div className="admin-page-tabs">
                    <button type="button" className={!pagePreview ? 'active' : ''} onClick={() => setPagePreview(false)}>Write</button>
                    <button type="button" className={pagePreview ? 'active' : ''} onClick={() => setPagePreview(true)}>Preview</button>
                  </div>
                  {pagePreview
                    ? <div className="admin-page-preview page-content" dangerouslySetInnerHTML={{ __html: renderMarkdown(pageForm.content) }} />
                    : <textarea rows="16" value={pageForm.content} onChange={(event) => setPageForm({ ...pageForm, content: event.target.value })} />}
                </div>
              </label>
              {pageForm.id && pageForm.is_published && <p className="muted">Storefront link: <code>/#/p/{pageForm.slug}</code></p>}
              <div className="admin-form-actions">
                <button className="act" type="submit">Save</button>
                <button className="act ghost" type="button" onClick={() => setPageForm(null)}>Cancel</button>
                {pageForm.id && <button className="act danger" type="button" onClick={() => removePage(pageForm)}>Delete</button>}
              </div>
            </form>
          )}

          {pages.length === 0 ? <p className="admin-empty">No pages yet.</p> : (
            <table className="admin-table">
              <thead><tr><th>Title</th><th>Slug</th><th>Footer group</th><th>In footer</th><th>Published</th><th></th></tr></thead>
              <tbody>
                {pages.map((page) => (
                  <tr key={page.id}>
                    <td>{page.title}</td>
                    <td><code>{page.slug}</code></td>
                    <td>{page.footer_group}</td>
                    <td>{page.show_in_footer ? 'Yes' : 'No'}</td>
                    <td>{page.is_published ? 'Yes' : <span className="muted">Draft</span>}</td>
                    <td className="admin-actions">
                      <button className="act" type="button" onClick={() => editPage(page)}>Edit</button>
                      <button className="act danger" type="button" onClick={() => removePage(page)}>Delete</button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      )}

      {tab === 'support' && (
        <section className="admin-panel">
          <div className="admin-filters">
            {['open', 'resolved', 'all'].map((value) => (
              <button key={value} type="button" className={threadStatus === value ? 'chip active' : 'chip'} onClick={() => setThreadStatus(value)}>{value}</button>
            ))}
          </div>
          {threads.length === 0 ? <p className="admin-empty">No conversations.</p> : (
            <table className="admin-table">
              <thead><tr><th>Customer</th><th>Order</th><th>Issue</th><th>Status</th><th>Rating</th><th>Last activity</th><th></th></tr></thead>
              <tbody>
                {threads.map((t) => (
                  <tr key={t.id}>
                    <td>{t.user?.email ?? '—'}</td>
                    <td>{t.order_id ? `#${t.order_id}` : '—'}</td>
                    <td>{ISSUE_LABELS[t.issue_type] ?? t.issue_type}</td>
                    <td><span className={`pill pill-${t.status === 'open' ? 'failed' : 'paid'}`}>{t.status}</span></td>
                    <td>{t.rating != null ? <span className="admin-review-stars" title={t.rating_comment || ''}>{'★'.repeat(t.rating)}<span className="dim">{'★'.repeat(5 - t.rating)}</span></span> : <span className="muted">—</span>}</td>
                    <td>{t.last_message_at ? new Date(t.last_message_at).toLocaleString() : '—'}</td>
                    <td className="admin-actions"><button className="act" type="button" onClick={() => openThread(t.id)}>Open</button></td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      )}

      {tab === 'footer' && (
        <section className="admin-panel">
          {!footerForm ? <p className="admin-empty">Loading…</p> : (
            <form className="admin-form" onSubmit={saveFooter}>
              <h3>Footer</h3>
              <p className="muted">The storefront footer. &ldquo;Useful Links&rdquo; also lists your published content pages; the links below are added after them.</p>
              <div className="admin-form-grid">
                <label>Copyright line<input maxLength="160" value={footerForm.copyright} onChange={(event) => setFooterForm({ ...footerForm, copyright: event.target.value })} placeholder="© {year} Grocerly" /></label>
                <label>App Store URL<input value={footerForm.app_store_url} onChange={(event) => setFooterForm({ ...footerForm, app_store_url: event.target.value })} placeholder="https://apps.apple.com/…" /></label>
                <label>Google Play URL<input value={footerForm.play_store_url} onChange={(event) => setFooterForm({ ...footerForm, play_store_url: event.target.value })} placeholder="https://play.google.com/…" /></label>
              </div>
              <label>Disclaimer / note<textarea rows="3" maxLength="600" value={footerForm.note} onChange={(event) => setFooterForm({ ...footerForm, note: event.target.value })} /></label>
              <p className="muted"><code>{'{year}'}</code> in the copyright line is replaced with the current year.</p>

              <fieldset className="admin-fieldset">
                <legend>Social links</legend>
                <div className="admin-form-grid">
                  {SOCIAL_PLATFORMS.map(([key, label]) => (
                    <label key={key}>{label}
                      <input value={footerForm.socials[key] ?? ''} placeholder="https://… (blank = hidden)"
                        onChange={(event) => setFooterForm({ ...footerForm, socials: { ...footerForm.socials, [key]: event.target.value } })} />
                    </label>
                  ))}
                </div>
              </fieldset>

              <fieldset className="admin-fieldset">
                <legend>Extra footer links</legend>
                {footerForm.links.map((link, index) => (
                  <div className="admin-variant-row" key={index}>
                    <input placeholder="Label" value={link.label} onChange={(event) => setFooterForm({ ...footerForm, links: footerForm.links.map((l, i) => i === index ? { ...l, label: event.target.value } : l) })} />
                    <input placeholder="https://…" value={link.url} onChange={(event) => setFooterForm({ ...footerForm, links: footerForm.links.map((l, i) => i === index ? { ...l, url: event.target.value } : l) })} />
                    <button type="button" className="act danger" onClick={() => setFooterForm({ ...footerForm, links: footerForm.links.filter((_, i) => i !== index) })}>Remove</button>
                  </div>
                ))}
                {footerForm.links.length < 12 && <button type="button" className="act" onClick={() => setFooterForm({ ...footerForm, links: [...footerForm.links, { label: '', url: '' }] })}>Add link</button>}
              </fieldset>

              <div className="admin-form-actions"><button className="act" type="submit">Save footer</button></div>
            </form>
          )}
        </section>
      )}

      {tab === 'branding' && (
        <section className="admin-panel">
          {!brandingForm ? <p className="admin-empty">Loading…</p> : (
            <form className="admin-form" onSubmit={saveBranding}>
              <h3>Store settings</h3>
              <p className="muted">Branding for the storefront. Current values are pre-filled; changes apply after the shopper reloads.</p>
              <div className="admin-form-grid">
                <label>Store name<input required maxLength="60" value={brandingForm.store_name} onChange={(event) => setBrandingForm({ ...brandingForm, store_name: event.target.value })} /></label>
                <label>Tagline<input maxLength="120" value={brandingForm.tagline} onChange={(event) => setBrandingForm({ ...brandingForm, tagline: event.target.value })} /></label>
                <label>Theme
                  <select value={brandingForm.theme} onChange={(event) => setBrandingForm({ ...brandingForm, theme: event.target.value })}>
                    <option value="light">Light</option>
                    <option value="dark">Dark</option>
                  </select>
                </label>
                <label>Layout width
                  <select value={brandingForm.layout_width} onChange={(event) => setBrandingForm({ ...brandingForm, layout_width: event.target.value })}>
                    <option value="boxed">Boxed &mdash; 1280px, centred (Blinkit-style)</option>
                    <option value="full">Full width</option>
                  </select>
                </label>
              </div>

              <label>Logo
                <div className="admin-image-field">
                  {brandingForm.logo_url && <img className="admin-image-preview" src={mediaUrl(brandingForm.logo_url)} alt="" onError={(event) => { event.currentTarget.style.display = 'none' }} />}
                  <input placeholder="Logo image URL, or upload →" value={brandingForm.logo_url} onChange={(event) => setBrandingForm({ ...brandingForm, logo_url: event.target.value })} />
                  <input type="file" accept="image/*" disabled={imgBusy} onChange={(event) => uploadImage(event.target.files?.[0], (url) => setBrandingForm((form) => ({ ...form, logo_url: url })))} />
                  {brandingForm.logo_url && <button type="button" className="act ghost" onClick={() => setBrandingForm({ ...brandingForm, logo_url: '' })}>Clear</button>}
                </div>
              </label>
              <label>Favicon
                <div className="admin-image-field">
                  {brandingForm.favicon_url && <img className="admin-image-preview" src={mediaUrl(brandingForm.favicon_url)} alt="" onError={(event) => { event.currentTarget.style.display = 'none' }} />}
                  <input placeholder="Favicon URL (.png / .ico / .svg), or upload →" value={brandingForm.favicon_url} onChange={(event) => setBrandingForm({ ...brandingForm, favicon_url: event.target.value })} />
                  <input type="file" accept="image/*" disabled={imgBusy} onChange={(event) => uploadImage(event.target.files?.[0], (url) => setBrandingForm((form) => ({ ...form, favicon_url: url })))} />
                  {brandingForm.favicon_url && <button type="button" className="act ghost" onClick={() => setBrandingForm({ ...brandingForm, favicon_url: '' })}>Clear</button>}
                </div>
              </label>

              <fieldset className="admin-fieldset">
                <legend>Colours</legend>
                <div className="admin-form-grid admin-color-grid">
                  {[
                    ['color_brand', 'Brand / buttons', 'Primary buttons, links and highlights'],
                    ['color_accent', 'Accent', 'Badges, sale tags and small highlights'],
                    ['color_heading', 'Headings & major text', 'Page titles and section headings'],
                  ].map(([key, label, hint]) => (
                    <label key={key} className="admin-color">{label}
                      <span>
                        <input type="color" value={brandingForm[key]} aria-label={`${label} colour`} onChange={(event) => setBrandingForm({ ...brandingForm, [key]: event.target.value })} />
                        <input value={brandingForm[key]} maxLength="7" spellCheck="false" aria-label={`${label} hex`} onChange={(event) => setBrandingForm({ ...brandingForm, [key]: event.target.value })} />
                      </span>
                      <em className="admin-color-hint">{hint}</em>
                    </label>
                  ))}
                </div>
                <p className="muted">The heading colour follows the theme unless you change it here.</p>
              </fieldset>

              <div className="admin-form-actions"><button className="act" type="submit">Save store settings</button></div>
            </form>
          )}
        </section>
      )}

      {tab === 'secure' && (
        <section className="admin-panel">
          {secureGate !== 'unlocked' ? (
            <div className="admin-form payments-gate">
              <h3>Secure access</h3>
              <p className="muted">
                {secureMethod === 'otp'
                  ? 'Enter the one-time code emailed to your admin address to continue.'
                  : 'Re-enter your admin password to change payment keys or your admin email / phone.'}
              </p>
              {secureMsg && <p className="muted">{secureMsg}</p>}
              <label>{secureMethod === 'otp' ? 'Email code' : 'Admin password'}
                <input type={secureMethod === 'otp' ? 'text' : 'password'}
                  inputMode={secureMethod === 'otp' ? 'numeric' : undefined}
                  autoComplete={secureMethod === 'otp' ? 'one-time-code' : 'current-password'}
                  maxLength={secureMethod === 'otp' ? 8 : undefined}
                  value={secureSecret}
                  onChange={(event) => setSecureSecret(secureMethod === 'otp' ? event.target.value.replace(/[^0-9]/g, '') : event.target.value)}
                  onKeyDown={(event) => { if (event.key === 'Enter') unlockSecure() }} />
              </label>
              <div className="admin-form-actions">
                <button className="act" type="button" disabled={!secureSecret.trim()} onClick={unlockSecure}>Unlock</button>
                {secureMethod === 'otp' && <button className="act ghost" type="button" onClick={challengeSecure}>Resend code</button>}
              </div>
            </div>
          ) : (
            <>
              <p className="muted">Unlocked for ~15 minutes — re-locks when you leave this section.</p>

              <form className="admin-form" onSubmit={saveAccount}>
                <h3>Admin account</h3>
                <div className="admin-form-grid">
                  <label>Name<input value={accountForm.name} onChange={(event) => setAccountForm({ ...accountForm, name: event.target.value })} /></label>
                  <label>Email<input type="email" value={accountForm.email} onChange={(event) => setAccountForm({ ...accountForm, email: event.target.value })} /></label>
                  <label>Phone<input value={accountForm.phone} onChange={(event) => setAccountForm({ ...accountForm, phone: event.target.value })} placeholder="+1…" /></label>
                </div>
                <p className="muted">Changing the email also changes the address a future one-time code is sent to.</p>
                <div className="admin-form-actions"><button className="act" type="submit">Save account</button></div>
              </form>

              {paymentsForm && settings && (
                <form className="admin-form" onSubmit={savePayments}>
                  <h3>Payments — Stripe</h3>
                  <p className="muted">
                    These override the server&rsquo;s <code>STRIPE_*</code> environment values and take effect immediately.
                    Current mode: <strong>{settings.payments?.stripe_mode ?? 'test'}</strong>.
                  </p>
                  <label>Publishable key
                    <input value={paymentsForm.stripe_key} placeholder="pk_test_… / pk_live_…" onChange={(event) => setPaymentsForm({ ...paymentsForm, stripe_key: event.target.value })} />
                  </label>
                  <label>Secret key
                    <input type="password" autoComplete="off" value={paymentsForm.stripe_secret}
                      placeholder={settings.payments?.stripe_secret_set ? `current: ${settings.payments.stripe_secret_hint} — leave blank to keep` : 'sk_test_… / sk_live_…'}
                      onChange={(event) => setPaymentsForm({ ...paymentsForm, stripe_secret: event.target.value })} />
                  </label>
                  <label>Webhook signing secret
                    <input type="password" autoComplete="off" value={paymentsForm.stripe_webhook_secret}
                      placeholder={settings.payments?.stripe_webhook_secret_set ? `current: ${settings.payments.stripe_webhook_secret_hint} — leave blank to keep` : 'whsec_…'}
                      onChange={(event) => setPaymentsForm({ ...paymentsForm, stripe_webhook_secret: event.target.value })} />
                  </label>
                  <p className="muted">Secrets are stored in the database and shown afterwards only as a hint. Use live keys only on an HTTPS store.</p>
                  <div className="admin-form-actions"><button className="act" type="submit">Save payment settings</button></div>
                </form>
              )}
            </>
          )}
        </section>
      )}

      {tab === 'settings' && (
        <section className="admin-panel">
          {!settings || !feesForm ? <p className="admin-empty">Loading settings…</p> : (
            <>
              <div className="admin-form">
                <h3>Payment</h3>
                <label className="admin-check">
                  <input type="checkbox" checked={!!settings.cod_enabled} onChange={(event) => saveSetting({ cod_enabled: event.target.checked })} />
                  Accept cash on delivery
                </label>
                <p className="muted">When on, customers can choose to pay with cash at checkout. Cash-on-delivery orders are confirmed immediately; mark them paid from the Orders tab once the courier collects the cash.</p>
              </div>

              <div className="admin-form">
                <h3>Delivery</h3>
                <label className="admin-check">
                  <input type="checkbox" checked={settings.rider_auto_assign !== false} onChange={(event) => saveSetting({ rider_auto_assign: event.target.checked })} />
                  Auto-assign riders to orders
                </label>
                <p className="muted">When an order becomes ready for delivery, the nearest on-shift rider linked to its store is assigned automatically (preferring riders with fewer active jobs). If none is eligible the order waits in the pickup pool. Manage riders and their stores under <strong>Riders</strong>.</p>
              </div>

              <form className="admin-form" onSubmit={saveFees}>
                <h3>Delivery &amp; charges</h3>

                <fieldset className="admin-fieldset">
                  <legend>Delivery fee</legend>
                  <label className="admin-radio-row">Charge model
                    <span>
                      <label><input type="radio" name="delivery_mode" checked={feesForm.delivery_mode === 'fixed'} onChange={() => setFeesForm({ ...feesForm, delivery_mode: 'fixed' })} /> Fixed</label>
                      <label><input type="radio" name="delivery_mode" checked={feesForm.delivery_mode === 'distance'} onChange={() => setFeesForm({ ...feesForm, delivery_mode: 'distance' })} /> By distance</label>
                    </span>
                  </label>
                  {feesForm.delivery_mode === 'fixed' ? (
                    <div className="admin-form-grid">
                      <label>Delivery fee ($)<input type="number" min="0" step="0.01" value={feesForm.delivery_fee} onChange={(event) => setFeesForm({ ...feesForm, delivery_fee: event.target.value })} /></label>
                    </div>
                  ) : (
                    <>
                      <div className="admin-pair">
                        <label>Fee near store ($)<input type="number" min="0" step="0.01" value={feesForm.delivery_near_fee} onChange={(event) => setFeesForm({ ...feesForm, delivery_near_fee: event.target.value })} /></label>
                        <label>Fee at edge of radius ($)<input type="number" min="0" step="0.01" value={feesForm.delivery_far_fee} onChange={(event) => setFeesForm({ ...feesForm, delivery_far_fee: event.target.value })} /></label>
                      </div>
                      <p className="muted">Linear from 0 km (near fee) to each store&rsquo;s delivery radius (far fee).{stores[0]?.delivery_radius_km ? ` e.g. ${money(toCents(feesForm.delivery_near_fee))} at the store, ${money(toCents(feesForm.delivery_far_fee))} at ${stores[0].delivery_radius_km} km.` : ''}</p>
                    </>
                  )}
                  <div className="admin-form-grid">
                    <label>Free delivery above ($)<input type="number" min="0" step="0.01" value={feesForm.free_delivery_threshold} onChange={(event) => setFeesForm({ ...feesForm, free_delivery_threshold: event.target.value })} /></label>
                  </div>
                </fieldset>

                <fieldset className="admin-fieldset">
                  <legend>Other charges</legend>
                  <div className="admin-form-grid">
                    <label>Handling fee ($)<input type="number" min="0" step="0.01" value={feesForm.handling_fee} onChange={(event) => setFeesForm({ ...feesForm, handling_fee: event.target.value })} /></label>
                    <label>Small-cart fee ($)<input type="number" min="0" step="0.01" value={feesForm.small_cart_fee} onChange={(event) => setFeesForm({ ...feesForm, small_cart_fee: event.target.value })} /></label>
                    <label>…applied below ($)<input type="number" min="0" step="0.01" value={feesForm.small_cart_min} onChange={(event) => setFeesForm({ ...feesForm, small_cart_min: event.target.value })} /></label>
                    <label>Tax rate (%)<input type="number" min="0" step="0.01" value={feesForm.tax_rate_pct} onChange={(event) => setFeesForm({ ...feesForm, tax_rate_pct: event.target.value })} /></label>
                  </div>
                </fieldset>

                <div className="admin-form-actions"><button className="act" type="submit">Save charges</button></div>
              </form>
            </>
          )}
        </section>
      )}
        </main>
      </div>

      {thread && (
        <div className="admin-drawer" role="presentation" onClick={() => setThread(null)}>
          <aside onClick={(event) => event.stopPropagation()}>
            <button className="admin-close" type="button" onClick={() => setThread(null)}>Close</button>
            <h3>{ISSUE_LABELS[thread.issue_type] ?? thread.issue_type}{thread.order_id ? ` · Order #${thread.order_id}` : ''}</h3>
            <p className="muted">{thread.user?.email} · {thread.status}
              {thread.status === 'open'
                ? <button className="act" type="button" style={{ marginLeft: 8 }} onClick={() => setThreadResolved('resolved')}>Mark resolved</button>
                : <button className="act ghost" type="button" style={{ marginLeft: 8 }} onClick={() => setThreadResolved('open')}>Re-open</button>}
            </p>
            {thread.rating != null && (
              <p className="admin-chat-rating">
                <span className="admin-review-stars">{'★'.repeat(thread.rating)}<span className="dim">{'★'.repeat(5 - thread.rating)}</span></span>
                <span className="muted"> customer rated this chat{thread.rated_at ? ` · ${new Date(thread.rated_at).toLocaleDateString()}` : ''}</span>
                {thread.rating_comment && <span className="admin-chat-rating-c">“{thread.rating_comment}”</span>}
              </p>
            )}
            <div className="chat-log">{(thread.messages ?? []).map((m) => (
              <div key={m.id} className={`chat-msg ${m.is_staff && m.user_id ? 'staff' : m.user_id ? 'customer' : 'system'}`}><span>{m.body}</span><em>{new Date(m.created_at).toLocaleString()}</em></div>
            ))}</div>
            <div className="chat-send">
              <input placeholder="Reply to the customer" value={threadReply} onChange={(event) => setThreadReply(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter') replyThread() }} />
              <button type="button" disabled={!threadReply.trim()} onClick={replyThread}>Send</button>
            </div>

            {thread.order && (() => {
              const o = thread.order
              const remaining = Math.max(0, o.total_cents - (o.refunded_amount_cents ?? 0))
              const stateOk = ['paid', 'partially_refunded', 'refund_pending'].includes(o.payment_status)
              const canRefund = !!o.stripe_payment_intent_id && stateOk && remaining > 0
              const blockReason = !canRefund && (
                remaining <= 0 || o.payment_status === 'refunded'
                  ? 'This order is fully refunded.'
                  : !o.stripe_payment_intent_id
                    ? 'No online payment to refund (cash on delivery). Use “Mark refunded” on the Orders tab.'
                    : 'This order is not in a refundable state.'
              )
              const selectedSum = (o.items ?? []).filter((i) => refundForm.items.includes(i.id)).reduce((s, i) => s + i.line_total_cents, 0)
              const bare = refundForm.items.length === 0 && !String(refundForm.amount).trim()
              const amountCents = refundForm.items.length ? selectedSum : Math.round(Number(refundForm.amount || 0) * 100)
              const amountOk = bare ? remaining > 0 : (amountCents > 0 && amountCents <= remaining)
              return (
                <div className="admin-form" style={{ marginTop: 16 }}>
                  <h4>Refund</h4>
                  <p className="muted">Paid {money(o.total_cents)} · refunded {money(o.refunded_amount_cents ?? 0)} · remaining {money(remaining)}</p>
                  {canRefund ? (
                    <>
                      {(o.items ?? []).map((item) => (
                        <label key={item.id} className="admin-check">
                          <input type="checkbox" checked={refundForm.items.includes(item.id)} onChange={(event) => setRefundForm((f) => ({ ...f, items: event.target.checked ? [...f.items, item.id] : f.items.filter((x) => x !== item.id) }))} />
                          {item.product_name}{item.variant_label ? ` · ${item.variant_label}` : ''} × {item.quantity} — {money(item.line_total_cents)}
                        </label>
                      ))}
                      <div className="admin-form-grid" style={{ marginTop: 10 }}>
                        <label>Or amount ($)<input type="number" min="0" step="0.01" disabled={refundForm.items.length > 0} value={refundForm.amount} onChange={(event) => setRefundForm({ ...refundForm, amount: event.target.value })} /></label>
                        <label>Reason<input value={refundForm.reason} onChange={(event) => setRefundForm({ ...refundForm, reason: event.target.value })} /></label>
                      </div>
                      {refundForm.items.length > 0 && <p className="muted">Selected items: {money(selectedSum)}{selectedSum > remaining ? ' — more than the remaining balance' : ' (tax and fees are refunded separately)'}.</p>}
                      <div className="admin-form-actions">
                        <button className="act" type="button" disabled={busyId === thread.id || !amountOk} onClick={issueRefund}>Issue refund</button>
                        {o.stripe_dashboard_url && <a className="act ghost" href={o.stripe_dashboard_url} target="_blank" rel="noreferrer">View in Stripe ↗</a>}
                      </div>
                    </>
                  ) : (
                    <>
                      <p className="muted">{blockReason}</p>
                      {o.stripe_dashboard_url && <div className="admin-form-actions"><a className="act ghost" href={o.stripe_dashboard_url} target="_blank" rel="noreferrer">View in Stripe ↗</a></div>}
                    </>
                  )}
                </div>
              )
            })()}
          </aside>
        </div>
      )}

      {customerDetail && (
        <div className="admin-drawer" role="presentation" onClick={() => setCustomerDetail(null)}>
          <aside onClick={(event) => event.stopPropagation()}>
            <button className="admin-close" type="button" onClick={() => setCustomerDetail(null)}>Close</button>
            {customerDetail.loading ? <p className="admin-empty">Loading…</p> : (
              <>
                <h3>{customerDetail.name}</h3>
                <p className="muted">{customerDetail.email} · {customerDetail.phone || 'no phone'} · joined {new Date(customerDetail.joined_at).toLocaleDateString()}</p>
                <label className="admin-check">
                  <input type="checkbox" checked={!!customerDetail.is_rider} onChange={(event) => toggleRider(customerDetail.id, event.target.checked)} />
                  Delivery rider (can log into the rider app and deliver orders)
                </label>
                <h4>Orders ({customerDetail.orders?.length ?? 0})</h4>
                <ul className="admin-order-list">
                  {(customerDetail.orders ?? []).map((order) => (
                    <li key={order.id}>
                      <strong>#{order.id}</strong> {money(order.total_cents)} · {order.payment_status} · {STATUS_LABELS[order.status] ?? order.status}
                      <span>{order.items?.length ?? 0} items · {new Date(order.created_at).toLocaleDateString()}</span>
                    </li>
                  ))}
                  {(customerDetail.orders ?? []).length === 0 && <li className="muted">No orders.</li>}
                </ul>
              </>
            )}
          </aside>
        </div>
      )}

      {riderDetail && (
        <div className="admin-drawer" role="presentation" onClick={() => setRiderDetail(null)}>
          <aside onClick={(event) => event.stopPropagation()}>
            <button className="admin-close" type="button" onClick={() => setRiderDetail(null)}>Close</button>
            {riderDetail.loading ? <p className="admin-empty">Loading…</p> : (
              <>
                <h3>{riderDetail.rider?.name}{riderDetail.view === 'reviews' ? ' — reviews' : ''}</h3>
                <p className="muted">{riderDetail.rider?.email} · {riderDetail.rider?.phone || 'no phone'}</p>

                {riderDetail.view === 'reviews' ? (
                  <div className="admin-review-overview">
                    <div className="admin-review-score">
                      <strong>{riderDetail.rider?.rating_avg != null ? riderDetail.rider.rating_avg.toFixed(1) : '—'}</strong>
                      <span>
                        <span className="admin-review-stars">{'★'.repeat(Math.round(riderDetail.rider?.rating_avg ?? 0))}<span className="dim">{'★'.repeat(5 - Math.round(riderDetail.rider?.rating_avg ?? 0))}</span></span>
                        <span className="muted"> {riderDetail.rider?.rating_count ?? 0} review{riderDetail.rider?.rating_count === 1 ? '' : 's'}</span>
                      </span>
                    </div>
                    <div className="admin-review-bars">
                      {[5, 4, 3, 2, 1].map((n) => {
                        const total = riderDetail.reviews?.length ?? 0
                        const c = (riderDetail.reviews ?? []).filter((r) => r.rating === n).length
                        return (
                          <div key={n} className="admin-review-bar">
                            <span>{n}★</span>
                            <span className="admin-review-bar-track"><span style={{ width: `${total ? (c / total) * 100 : 0}%` }} /></span>
                            <span>{c}</span>
                          </div>
                        )
                      })}
                    </div>
                  </div>
                ) : (
                  <>
                    <div className="admin-rider-stats">
                      <span><strong>{riderDetail.rider?.completed_deliveries ?? 0}</strong> delivered</span>
                      <span><strong>{riderDetail.rider?.active_deliveries ?? 0}</strong> active now</span>
                      <span><strong>{riderDetail.rider?.rating_avg != null ? `★ ${riderDetail.rider.rating_avg.toFixed(1)}` : '—'}</strong> {riderDetail.rider?.rating_count ?? 0} rating{riderDetail.rider?.rating_count === 1 ? '' : 's'}</span>
                      <span><strong>{riderDetail.rider?.acceptance_rate != null ? `${Math.round(riderDetail.rider.acceptance_rate * 100)}%` : '—'}</strong> offers accepted{riderDetail.rider?.offers_count ? ` (${riderDetail.rider.offers_count})` : ''}</span>
                      <span><strong>{riderDetail.rider?.declined_count ?? 0} / {riderDetail.rider?.missed_count ?? 0}</strong> rejected / missed</span>
                    </div>

                    <h4>Attendance</h4>
                    <p className="muted">{riderStatusChip(riderDetail.rider ?? {})}</p>
                    <div className="admin-month-nav">
                      <button type="button" className="act ghost" onClick={() => setRiderMonth((m) => new Date(m.getFullYear(), m.getMonth() - 1, 1))}>&lsaquo; Prev</button>
                      <strong>{riderMonth.toLocaleDateString([], { month: 'long', year: 'numeric' })}</strong>
                      <button type="button" className="act ghost" disabled={riderMonth.getFullYear() === new Date().getFullYear() && riderMonth.getMonth() === new Date().getMonth()} onClick={() => setRiderMonth((m) => new Date(m.getFullYear(), m.getMonth() + 1, 1))}>Next &rsaquo;</button>
                    </div>
                    {!riderReport || riderReport.loading ? <p className="admin-empty">Loading…</p> : (
                      <>
                        <p className="muted">Completed days only — counting from {new Date(riderReport.active_from).toLocaleDateString()}{riderReport.today?.on_the_clock ? ` · on the clock now, ${fmtWorked(riderReport.today.worked_minutes)} today` : ''}</p>
                        <div className="admin-rider-stats">
                          <span><strong>{riderReport.summary.days_full}</strong> full days (&ge; {fmtWorked(riderReport.target_minutes)})</span>
                          <span><strong>{riderReport.summary.days_short}</strong> short days</span>
                          <span><strong>{riderReport.summary.days_off}</strong> days off</span>
                          <span><strong>{fmtWorked(riderReport.summary.total_worked_minutes)}</strong> total worked</span>
                          <span><strong>{fmtWorked(riderReport.summary.avg_worked_minutes)}</strong> avg / completed day</span>
                        </div>
                        <table className="admin-table">
                          <thead><tr><th>Date</th><th></th><th>In</th><th>Out</th><th>Worked</th><th>Breaks</th></tr></thead>
                          <tbody>
                            {riderReport.days.map((d) => (
                              <tr key={d.date} className={(d.status === 'off' || d.status === 'pre') ? 'admin-day-off' : ''}>
                                <td>{new Date(d.date).toLocaleDateString([], { weekday: 'short', day: 'numeric', month: 'short' })}</td>
                                <td><span style={{ color: DAY_STATUS[d.status].color, fontWeight: 600 }}>{DAY_STATUS[d.status].label}</span></td>
                                <td>{d.first_in ? new Date(d.first_in).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : '—'}</td>
                                <td>{d.shifts === 0 ? '—' : d.last_out ? new Date(d.last_out).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' }) : <span className="muted">open</span>}</td>
                                <td>{d.worked_minutes ? fmtWorked(d.worked_minutes) : '—'}</td>
                                <td>{d.break_minutes ? fmtWorked(d.break_minutes) : '—'}</td>
                              </tr>
                            ))}
                            {riderReport.days.length === 0 && <tr><td colSpan={6} className="muted">No days in range.</td></tr>}
                          </tbody>
                        </table>
                      </>
                    )}
                  </>
                )}

                <h4>{riderDetail.view === 'reviews' ? 'Recent reviews' : 'Customer reviews'} ({riderDetail.reviews?.length ?? 0})</h4>
                <p className="muted">Comments are for admins only — the rider never sees them.</p>
                <ul className="admin-review-list">
                  {(riderDetail.reviews ?? []).map((rv) => (
                    <li key={rv.id}>
                      <div className="admin-review-head">
                        <span className="admin-review-stars">{'★'.repeat(rv.rating)}<span className="dim">{'★'.repeat(5 - rv.rating)}</span></span>
                        <span className="muted">Order #{rv.order_id} · {rv.source === 'chat' ? 'from chat' : 'delivery'} · {new Date(rv.at).toLocaleDateString()}</span>
                      </div>
                      {rv.comment ? <p className="admin-review-comment">{rv.comment}</p> : <p className="muted">No comment.</p>}
                    </li>
                  ))}
                  {(riderDetail.reviews ?? []).length === 0 && <li className="muted">No reviews yet.</li>}
                </ul>
              </>
            )}
          </aside>
        </div>
      )}
    </div>
  )
}
