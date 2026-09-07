import { useCallback, useEffect, useRef, useState } from 'react'
import MapPicker from './MapPicker'
import { BarChart, Delta, GroupedBars, PieChart } from './Charts'
import { renderMarkdown } from './markdown'
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
// Left sidebar vs top-right. Support/Settings stay top-right (used less often,
// and Support carries the live badge next to the notification bell).
const PRIMARY_TABS = ['dashboard', 'orders', 'products', 'categories', 'customers', 'stores', 'branding', 'secure']
const TOP_TABS = ['support', 'settings']
const TAB_LABELS = {
  dashboard: 'Dashboard', orders: 'Orders', products: 'Products', categories: 'Categories',
  customers: 'Customers', stores: 'Stores', branding: 'Store settings', secure: 'Secure access',
  homepage: 'Homepage', support: 'Support', settings: 'Settings',
}
const TAB_ICONS = {
  dashboard: '\u{1F4CA}', orders: '\u{1F9FE}', products: '\u{1F4E6}', categories: '\u{1F5C2}️',
  customers: '\u{1F465}', stores: '\u{1F3EC}', branding: '\u{1F3A8}', secure: '\u{1F510}',
  homepage: '\u{1F5BC}️',
}
const EMPTY_BRANDING = { store_name: '', tagline: '', logo_url: '', favicon_url: '', theme: 'light', color_brand: '#1f7a3d', color_accent: '#ffd23f', color_heading: '#18211c' }
const SOCIAL_PLATFORMS = [['facebook', 'Facebook'], ['x', 'X / Twitter'], ['instagram', 'Instagram'], ['linkedin', 'LinkedIn'], ['youtube', 'YouTube']]
const EMPTY_FOOTER = { copyright: '© {year} Grocerly', note: '', app_store_url: '', play_store_url: '', socials: { facebook: '', x: '', instagram: '', linkedin: '', youtube: '' }, links: [] }

const ISSUE_LABELS = {
  item_missing: 'Item missing', item_damaged: 'Item damaged', wrong_item: 'Wrong item',
  not_delivered: 'Not delivered', payment_issue: 'Payment issue', other: 'Other',
}

const EMPTY_PRODUCT = { category_id: '', name: '', sku: '', price: '', inventory_quantity: 0, description: '', image_url: '', is_active: true, variants: [] }
const EMPTY_VARIANT = { label: '', sku: '', price: '', stock: 0, image_url: '', is_active: true }

const variantRowsFrom = (product) => (product.variants ?? []).map((v) => ({
  id: v.id, label: v.label, sku: v.sku, price: (v.price_cents / 100).toFixed(2),
  stock: v.inventory_quantity, image_url: v.image_url ?? '', is_active: v.is_active,
}))
const EMPTY_CATEGORY = { name: '', slug: '', sort_order: 0, is_active: true }
const EMPTY_STORE = { name: '', line1: '', line2: '', city: '', state: '', postal_code: '', latitude: '', longitude: '', delivery_radius_km: 5, is_active: true }
const EMPTY_BANNER = { image_url: '', headline: '', category_slug: '', link_url: '', sort_order: 0, is_active: true }
const EMPTY_TILE = { title: '', image_url: '', category_slug: '', link_url: '', sort_order: 0, is_active: true }
const EMPTY_PAGE = { title: '', slug: '', content: '', footer_group: 'useful_links', show_in_footer: true, is_published: true, sort_order: 0 }

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
  const [orders, setOrders] = useState([])
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [customers, setCustomers] = useState([])
  const [customerDetail, setCustomerDetail] = useState(null)
  const [statusFilter, setStatusFilter] = useState('all')
  const [productSearch, setProductSearch] = useState('')
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
  const [courierDraft, setCourierDraft] = useState({})
  const [riders, setRiders] = useState([])
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

  const loadOrders = useCallback(() => {
    const query = statusFilter === 'all' ? '' : `?status=${statusFilter}`
    fetch(`${API_URL}/admin/orders${query}`, { headers: authHeaders() }).then(readJson)
      .then((data) => setOrders(data.data ?? [])).catch(() => setMessage('Could not load orders.'))
    fetch(`${API_URL}/admin/riders`, { headers: authHeaders() }).then(readJson)
      .then((data) => setRiders(data.data ?? [])).catch(() => {})
  }, [authHeaders, statusFilter])

  const loadProducts = useCallback(() => {
    const query = productSearch.trim() ? `?search=${encodeURIComponent(productSearch.trim())}` : ''
    fetch(`${API_URL}/admin/products${query}`, { headers: authHeaders() }).then(readJson)
      .then((data) => setProducts(data.data ?? [])).catch(() => setMessage('Could not load products.'))
  }, [authHeaders, productSearch])

  const loadCategories = useCallback(() => {
    fetch(`${API_URL}/admin/categories`, { headers: authHeaders() }).then(readJson)
      .then((data) => setCategories(data.data ?? [])).catch(() => setMessage('Could not load categories.'))
  }, [authHeaders])

  const loadCustomers = useCallback(() => {
    fetch(`${API_URL}/admin/customers`, { headers: authHeaders() }).then(readJson)
      .then((data) => setCustomers(data.data ?? [])).catch(() => setMessage('Could not load customers.'))
  }, [authHeaders])

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
    fetch(`${API_URL}/admin/stores`, { headers: authHeaders() }).then(readJson)
      .then((data) => setStores(data.data ?? [])).catch(() => setMessage('Could not load stores.'))
  }, [authHeaders])

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

  useEffect(() => { loadMetrics() }, [loadMetrics])
  useEffect(() => { loadPages() }, [loadPages])
  useEffect(() => { if (tab === 'dashboard') loadChart() }, [tab, loadChart])
  useEffect(() => { if (tab === 'dashboard') loadCompare() }, [tab, loadCompare])
  useEffect(() => { if (tab === 'orders') loadOrders() }, [tab, loadOrders])
  useEffect(() => { if (tab === 'products') { loadProducts(); loadCategories() } }, [tab, loadProducts, loadCategories])
  useEffect(() => { if (tab === 'categories') loadCategories() }, [tab, loadCategories])
  useEffect(() => { if (tab === 'customers') loadCustomers() }, [tab, loadCustomers])
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
    check()
    const timer = setInterval(check, 10000)
    return () => { stopped = true; clearInterval(timer) }
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

  function editPage(page) {
    setPagePreview(false)
    setPageForm({
      id: page.id, title: page.title ?? '', slug: page.slug ?? '', content: page.content ?? '',
      footer_group: page.footer_group ?? 'useful_links', show_in_footer: page.show_in_footer,
      is_published: page.is_published, sort_order: page.sort_order ?? 0,
    })
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
    const { id, price, variants, ...rest } = productForm
    const payload = { ...rest, category_id: Number(rest.category_id), inventory_quantity: Number(rest.inventory_quantity), price_cents: Math.round(Number(price) * 100), image_url: rest.image_url?.trim() || null }
    const rows = (variants ?? []).filter((row) => row.id || !row._delete)
    if (id || rows.length) {
      payload.variants = rows.map((row) => ({
        ...(row.id ? { id: row.id } : {}),
        ...(row._delete ? { _delete: true } : {}),
        label: (row.label || '').trim(),
        sku: (row.sku || '').trim(),
        price_cents: Math.round(Number(row.price || 0) * 100),
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
              {pages.map((p) => (
                <button key={p.id} type="button" className={tab === 'pages' && pageForm?.id === p.id ? 'active' : ''} onClick={() => { goTab('pages'); editPage(p) }}>{p.title}</button>
              ))}
              <button type="button" className="nav-sub-add" onClick={() => { goTab('pages'); setPagePreview(false); setPageForm({ ...EMPTY_PAGE }) }}>+ New page</button>
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
                <article className="metric"><span>Paid revenue</span><strong>{money(metrics.revenue_cents)}</strong></article>
                <article className="metric"><span>Orders</span><strong>{metrics.orders_total}</strong></article>
                <article className="metric"><span>Awaiting fulfilment</span><strong>{metrics.awaiting_fulfilment}</strong></article>
                <article className="metric"><span>Customers</span><strong>{metrics.customers}</strong></article>
                <article className="metric"><span>Products</span><strong>{metrics.products}</strong></article>
                <article className="metric"><span>Low stock (&le;5)</span><strong>{metrics.low_stock}</strong></article>
              </>
            )}
          </section>

          <section className="admin-panel">
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
                    <div><span className="compare-measure">{compare.current.label}</span><strong>{fmt(cur)}</strong></div>
                    <Delta current={cur} previous={prev} />
                    <div className="compare-vs"><span className="compare-measure">{compare.previous.label}</span><strong>{fmt(prev)}</strong></div>
                  </div>
                  <GroupedBars
                    data={compare.series.map((point) => ({ label: point.label, a: point.previous?.[compareMetric] ?? 0, b: point.current?.[compareMetric] ?? 0 }))}
                    format={fmt}
                    legend={{ a: compare.previous.label, b: compare.current.label }}
                  />
                </>
              )
            })()}
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
                <BarChart
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
        </>
      )}

      {tab === 'orders' && (
        <section className="admin-panel">
          <div className="admin-filters">
            {STATUS_FILTERS.map((value) => (
              <button key={value} type="button" className={statusFilter === value ? 'chip active' : 'chip'} onClick={() => setStatusFilter(value)}>
                {value === 'all' ? 'All' : STATUS_LABELS[value]}
              </button>
            ))}
          </div>
          {orders.length === 0 ? <p className="admin-empty">No orders for this filter.</p> : (
            <table className="admin-table">
              <thead><tr><th>#</th><th>Customer</th><th>Placed</th><th>Items</th><th>Total</th><th>Method</th><th>Payment</th><th>Delivery</th><th>Courier</th><th>Actions</th></tr></thead>
              <tbody>
                {orders.map((order) => (
                  <tr key={order.id}>
                    <td>{order.id}</td>
                    <td>{order.user?.email ?? '—'}{(order.delivery_address?.phone || order.user?.phone) && <span className="admin-note">☎ {order.delivery_address?.phone || order.user?.phone}</span>}{order.delivery_instructions && <span className="admin-note" title={order.delivery_instructions}>&ldquo;{order.delivery_instructions}&rdquo;</span>}</td>
                    <td>{new Date(order.created_at).toLocaleDateString()}</td>
                    <td>{order.items?.length ?? 0}</td>
                    <td>{money(order.total_cents)}</td>
                    <td>{order.payment_method === 'cod' ? 'Cash on delivery' : 'Card'}</td>
                    <td><span className={`pill pill-${order.payment_status}`}>{order.payment_status}</span></td>
                    <td>{STATUS_LABELS[order.status] ?? order.status}</td>
                    <td className="admin-courier">
                      {riders.length > 0 && (
                        <select value={order.delivery_partner_id ?? ''} disabled={busyId === order.id}
                          onChange={(event) => patchOrder(order, { delivery_partner_id: event.target.value ? Number(event.target.value) : null })}>
                          <option value="">— rider —</option>
                          {riders.map((r) => <option key={r.id} value={r.id}>{r.name}</option>)}
                        </select>
                      )}
                      <input value={courierDraft[order.id] ?? (order.delivery_partner_id ? '' : (order.courier_name ?? ''))} placeholder="or type a name"
                        onChange={(event) => setCourierDraft((current) => ({ ...current, [order.id]: event.target.value }))} />
                      <button type="button" disabled={busyId === order.id} onClick={() => patchOrder(order, { courier_name: (courierDraft[order.id] ?? order.courier_name ?? '').trim() || null, delivery_partner_id: null })}>Save</button>
                    </td>
                    <td className="admin-actions">
                      {order.payment_method === 'cod' && order.payment_status !== 'paid' && order.status !== 'cancelled' && (
                        <button type="button" disabled={busyId === order.id} className="act" onClick={() => patchOrder(order, { cash_collected: true })}>Mark cash collected</button>
                      )}
                      {(order.payment_status === 'refund_pending' || (order.payment_status === 'paid' && order.status === 'cancelled')) && (
                        order.stripe_payment_intent_id
                          ? <button type="button" disabled={busyId === order.id} className="act" onClick={() => refundOrder(order)}>Refund via Stripe</button>
                          : <button type="button" disabled={busyId === order.id} className="act" onClick={() => patchOrder(order, { refunded: true })}>Mark refunded</button>
                      )}
                      {order.payment_status === 'refunded' && order.stripe_dashboard_url && (
                        <a className="act ghost" href={order.stripe_dashboard_url} target="_blank" rel="noreferrer">View in Stripe ↗</a>
                      )}
                      {(NEXT_ACTIONS[order.status] ?? []).length === 0 && order.payment_status === 'paid' && <span className="muted">—</span>}
                      {(NEXT_ACTIONS[order.status] ?? []).map(([status, label]) => (
                        <button key={status} type="button" disabled={busyId === order.id} className={status === 'cancelled' ? 'act danger' : 'act'} onClick={() => patchOrder(order, { status })}>{label}</button>
                      ))}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </section>
      )}

      {tab === 'products' && (
        <section className="admin-panel">
          <div className="admin-toolbar">
            <input className="admin-search" value={productSearch} placeholder="Search name or SKU" onChange={(event) => setProductSearch(event.target.value)} />
            <button className="act" type="button" onClick={() => setProductForm({ ...EMPTY_PRODUCT, category_id: categories[0]?.id ?? '' })}>New product</button>
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
                <label>Inventory<input type="number" min="0" value={productForm.inventory_quantity} onChange={(event) => setProductForm({ ...productForm, inventory_quantity: event.target.value })} /></label>
                <label className="admin-check"><input type="checkbox" checked={productForm.is_active} onChange={(event) => setProductForm({ ...productForm, is_active: event.target.checked })} /> Active</label>
              </div>
              <label>Image
                <div className="admin-image-field">
                  {productForm.image_url && <img src={productForm.image_url} alt="" className="admin-image-preview" onError={(event) => { event.currentTarget.style.display = 'none' }} />}
                  <input placeholder="Image URL, or upload →" value={productForm.image_url ?? ''} onChange={(event) => setProductForm({ ...productForm, image_url: event.target.value })} />
                  <input type="file" accept="image/*" disabled={imgBusy} onChange={(event) => uploadImage(event.target.files?.[0], (url) => setProductForm((form) => ({ ...form, image_url: url })))} />
                  {productForm.image_url && <button type="button" className="act ghost" onClick={() => setProductForm({ ...productForm, image_url: '' })}>Clear</button>}
                </div>
              </label>
              <label>Description<textarea rows="2" value={productForm.description ?? ''} onChange={(event) => setProductForm({ ...productForm, description: event.target.value })} /></label>

              <fieldset className="admin-fieldset">
                <legend>Options / variants</legend>
                <p className="muted">Leave empty for a single-price product. Add a row per variant &mdash; pack size, weight, colour, flavour, or a mix (e.g. &ldquo;1 kg&rdquo;, &ldquo;Red / Large&rdquo;). Each has its own price, stock, SKU and image.</p>
                {(productForm.variants ?? []).map((row, index) => row._delete ? null : (
                  <div className="admin-variant-row" key={row.id ?? `new-${index}`}>
                    <input placeholder="Label (1 kg, Red / Large…)" value={row.label} onChange={(event) => setProductForm({ ...productForm, variants: productForm.variants.map((r, i) => i === index ? { ...r, label: event.target.value } : r) })} />
                    <input placeholder="SKU" value={row.sku} onChange={(event) => setProductForm({ ...productForm, variants: productForm.variants.map((r, i) => i === index ? { ...r, sku: event.target.value } : r) })} />
                    <input type="number" min="0" step="0.01" placeholder="Price $" value={row.price} onChange={(event) => setProductForm({ ...productForm, variants: productForm.variants.map((r, i) => i === index ? { ...r, price: event.target.value } : r) })} />
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

              <div className="admin-form-actions">
                <button className="act" type="submit">Save</button>
                <button className="act ghost" type="button" onClick={() => setProductForm(null)}>Cancel</button>
              </div>
            </form>
          )}

          {products.length === 0 ? <p className="admin-empty">No products.</p> : (
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
                    <td>{packs ? `${money(Math.min(...product.variants.filter((v) => v.is_active).map((v) => v.price_cents)))}+` : money(product.price_cents)}</td>
                    <td className={product.inventory_quantity <= 5 ? 'low' : ''}>{packs ? '—' : product.inventory_quantity}</td>
                    <td>{packs || '—'}</td>
                    <td>{product.is_active ? 'Yes' : 'No'}</td>
                    <td className="admin-actions">
                      <button className="act" type="button" onClick={() => setProductForm({ id: product.id, category_id: product.category_id, name: product.name, sku: product.sku, price: (product.price_cents / 100).toFixed(2), inventory_quantity: product.inventory_quantity, description: product.description ?? '', image_url: product.image_url ?? '', is_active: product.is_active, variants: variantRowsFrom(product) })}>Edit</button>
                      <button className="act danger" type="button" onClick={() => removeProduct(product)}>Delete</button>
                    </td>
                  </tr>
                )})}
              </tbody>
            </table>
          )}
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

          {categories.length === 0 ? <p className="admin-empty">No categories.</p> : (
            <table className="admin-table">
              <thead><tr><th>Name</th><th>Slug</th><th>Products</th><th>Sort</th><th>Active</th><th></th></tr></thead>
              <tbody>
                {categories.map((category) => (
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
        </section>
      )}

      {tab === 'customers' && (
        <section className="admin-panel">
          {customers.length === 0 ? <p className="admin-empty">No customers yet.</p> : (
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

          {stores.length === 0 ? <p className="admin-empty">No stores yet. Add one to switch on delivery-area checks.</p> : (
            <table className="admin-table">
              <thead><tr><th>Name</th><th>Address</th><th>Radius</th><th>Location</th><th>Active</th><th></th></tr></thead>
              <tbody>
                {stores.map((store) => (
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
        </section>
      )}

      {tab === 'homepage' && (
        <section className="admin-panel">
          <h3 className="admin-subhead">Promo banners</h3>
          <div className="admin-toolbar">
            <button className="act" type="button" onClick={() => setBannerForm({ ...EMPTY_BANNER })}>New banner</button>
            <span className="muted">The first (lowest order) is the full-width hero; the rest form the strip below it.</span>
          </div>

          {bannerForm && (
            <form className="admin-form" onSubmit={saveBanner}>
              <h3>{bannerForm.id ? `Edit banner #${bannerForm.id}` : 'New banner'}</h3>
              <div className="admin-image-field">
                {bannerForm.image_url
                  ? <img className="admin-banner-preview" src={bannerForm.image_url} alt="" />
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
              <thead><tr><th>Preview</th><th>Headline</th><th>Target</th><th>Order</th><th>Active</th><th></th></tr></thead>
              <tbody>
                {banners.map((banner) => (
                  <tr key={banner.id}>
                    <td><img className="admin-banner-thumb" src={banner.image_url} alt="" /></td>
                    <td>{banner.headline || <span className="muted">—</span>}</td>
                    <td>{banner.category_slug ? `#${banner.category_slug}` : (banner.link_url || <span className="muted">—</span>)}</td>
                    <td>{banner.sort_order}</td>
                    <td>{banner.is_active ? 'Yes' : 'No'}</td>
                    <td className="admin-actions">
                      <button className="act" type="button" onClick={() => setBannerForm({ id: banner.id, image_url: banner.image_url ?? '', headline: banner.headline ?? '', category_slug: banner.category_slug ?? '', link_url: banner.link_url ?? '', sort_order: banner.sort_order ?? 0, is_active: banner.is_active })}>Edit</button>
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
                  ? <img className="admin-banner-thumb" src={tileForm.image_url} alt="" />
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
                    <td>{tile.image_url ? <img className="admin-banner-thumb" src={tile.image_url} alt="" /> : <span className="muted">category</span>}</td>
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
            <button className="act" type="button" onClick={() => { setPagePreview(false); setPageForm({ ...EMPTY_PAGE }) }}>New page</button>
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
                <label className="admin-check"><input type="checkbox" checked={pageForm.show_in_footer} onChange={(event) => setPageForm({ ...pageForm, show_in_footer: event.target.checked })} /> Show in footer</label>
                <label className="admin-check"><input type="checkbox" checked={pageForm.is_published} onChange={(event) => setPageForm({ ...pageForm, is_published: event.target.checked })} /> Published</label>
              </div>
              <label>Content (Markdown)
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
              <thead><tr><th>Customer</th><th>Order</th><th>Issue</th><th>Status</th><th>Last activity</th><th></th></tr></thead>
              <tbody>
                {threads.map((t) => (
                  <tr key={t.id}>
                    <td>{t.user?.email ?? '—'}</td>
                    <td>{t.order_id ? `#${t.order_id}` : '—'}</td>
                    <td>{ISSUE_LABELS[t.issue_type] ?? t.issue_type}</td>
                    <td><span className={`pill pill-${t.status === 'open' ? 'failed' : 'paid'}`}>{t.status}</span></td>
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
              </div>

              <label>Logo
                <div className="admin-image-field">
                  {brandingForm.logo_url && <img className="admin-image-preview" src={brandingForm.logo_url} alt="" onError={(event) => { event.currentTarget.style.display = 'none' }} />}
                  <input placeholder="Logo image URL, or upload →" value={brandingForm.logo_url} onChange={(event) => setBrandingForm({ ...brandingForm, logo_url: event.target.value })} />
                  <input type="file" accept="image/*" disabled={imgBusy} onChange={(event) => uploadImage(event.target.files?.[0], (url) => setBrandingForm((form) => ({ ...form, logo_url: url })))} />
                  {brandingForm.logo_url && <button type="button" className="act ghost" onClick={() => setBrandingForm({ ...brandingForm, logo_url: '' })}>Clear</button>}
                </div>
              </label>
              <label>Favicon
                <div className="admin-image-field">
                  {brandingForm.favicon_url && <img className="admin-image-preview" src={brandingForm.favicon_url} alt="" onError={(event) => { event.currentTarget.style.display = 'none' }} />}
                  <input placeholder="Favicon URL (.png / .ico / .svg), or upload →" value={brandingForm.favicon_url} onChange={(event) => setBrandingForm({ ...brandingForm, favicon_url: event.target.value })} />
                  <input type="file" accept="image/*" disabled={imgBusy} onChange={(event) => uploadImage(event.target.files?.[0], (url) => setBrandingForm((form) => ({ ...form, favicon_url: url })))} />
                  {brandingForm.favicon_url && <button type="button" className="act ghost" onClick={() => setBrandingForm({ ...brandingForm, favicon_url: '' })}>Clear</button>}
                </div>
              </label>

              <fieldset className="admin-fieldset">
                <legend>Colours</legend>
                <div className="admin-form-grid">
                  {[['color_brand', 'Brand / buttons'], ['color_accent', 'Accent'], ['color_heading', 'Headings & major text']].map(([key, label]) => (
                    <label key={key} className="admin-color">{label}
                      <span>
                        <input type="color" value={brandingForm[key]} onChange={(event) => setBrandingForm({ ...brandingForm, [key]: event.target.value })} />
                        <input value={brandingForm[key]} maxLength="7" onChange={(event) => setBrandingForm({ ...brandingForm, [key]: event.target.value })} />
                      </span>
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
            <div className="chat-log">{(thread.messages ?? []).map((m) => (
              <div key={m.id} className={`chat-msg ${m.is_staff && m.user_id ? 'staff' : m.user_id ? 'customer' : 'system'}`}><span>{m.body}</span><em>{new Date(m.created_at).toLocaleString()}</em></div>
            ))}</div>
            <div className="chat-send">
              <input placeholder="Reply to the customer" value={threadReply} onChange={(event) => setThreadReply(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter') replyThread() }} />
              <button type="button" disabled={!threadReply.trim()} onClick={replyThread}>Send</button>
            </div>

            {thread.order && (
              <div className="admin-form" style={{ marginTop: 16 }}>
                <h4>Refund</h4>
                <p className="muted">Paid {money(thread.order.total_cents)} · refunded {money(thread.order.refunded_amount_cents ?? 0)} · remaining {money(thread.order.total_cents - (thread.order.refunded_amount_cents ?? 0))}</p>
                {(thread.order.items ?? []).map((item) => (
                  <label key={item.id} className="admin-check">
                    <input type="checkbox" checked={refundForm.items.includes(item.id)} onChange={(event) => setRefundForm((f) => ({ ...f, items: event.target.checked ? [...f.items, item.id] : f.items.filter((x) => x !== item.id) }))} />
                    {item.product_name}{item.variant_label ? ` · ${item.variant_label}` : ''} × {item.quantity} — {money(item.line_total_cents)}
                  </label>
                ))}
                <div className="admin-form-grid" style={{ marginTop: 10 }}>
                  <label>Or amount ($)<input type="number" min="0" step="0.01" disabled={refundForm.items.length > 0} value={refundForm.amount} onChange={(event) => setRefundForm({ ...refundForm, amount: event.target.value })} /></label>
                  <label>Reason<input value={refundForm.reason} onChange={(event) => setRefundForm({ ...refundForm, reason: event.target.value })} /></label>
                </div>
                <div className="admin-form-actions">
                  <button className="act" type="button" disabled={busyId === thread.id || (thread.order.total_cents - (thread.order.refunded_amount_cents ?? 0)) <= 0} onClick={issueRefund}>Issue refund</button>
                  {thread.order.stripe_dashboard_url && <a className="act ghost" href={thread.order.stripe_dashboard_url} target="_blank" rel="noreferrer">View in Stripe ↗</a>}
                </div>
              </div>
            )}
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
    </div>
  )
}
