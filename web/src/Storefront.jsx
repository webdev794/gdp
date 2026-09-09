import { useEffect, useMemo, useRef, useState } from 'react'
import { CardElement, Elements, useElements, useStripe } from '@stripe/react-stripe-js'
import { loadStripe } from '@stripe/stripe-js'
import { renderMarkdown } from './markdown'
import { mediaUrl } from './mediaUrl'
import { PageSection } from './PageSections'
import './StorefrontBase.css'
import './Storefront.css'
import './Checkout.css'

const API_URL = import.meta.env.VITE_API_URL ?? 'http://127.0.0.1:8000/api'
const stripePromise = import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY ? loadStripe(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY) : null
const foodImg = (ingredient) => `https://www.themealdb.com/images/ingredients/${encodeURIComponent(ingredient)}-Medium.png`
const fallbackProducts = [
  { id: 1, name: 'Organic Bananas', price_cents: 299, category: { name: 'Fresh Produce' }, image_url: foodImg('Banana') },
  { id: 2, name: 'Gala Apples', price_cents: 449, category: { name: 'Fresh Produce' }, image_url: foodImg('Apples') },
  { id: 3, name: 'Large Brown Eggs', price_cents: 599, category: { name: 'Dairy and Eggs' }, image_url: foodImg('Egg') },
  { id: 4, name: 'Whole Milk', price_cents: 429, category: { name: 'Dairy and Eggs' }, image_url: foodImg('Milk') },
  { id: 5, name: 'Long Grain Rice', price_cents: 699, category: { name: 'Pantry Staples' }, image_url: foodImg('Rice') },
  { id: 6, name: 'Pasta', price_cents: 249, category: { name: 'Pantry Staples' }, image_url: foodImg('Spaghetti') },
]
const categoriesFallback = [
  { id: 1, name: 'Fresh Produce', image_url: foodImg('Tomato') },
  { id: 2, name: 'Dairy and Eggs', image_url: foodImg('Milk') },
  { id: 3, name: 'Pantry Staples', image_url: foodImg('Rice') },
]

function price(cents) { return `$${(cents / 100).toFixed(2)}` }

// How to title a chosen option. If the variant label already carries the
// product identity ("Large Spinach") show it alone; if it's just an attribute
// ("Green", "1 kg") keep the product name for context ("Baby Spinach · Green").
function variantTitle(productName, variantLabel) {
  const name = productName ?? ''
  if (!variantLabel) return name
  const words = name.toLowerCase().split(/\s+/).filter((w) => w.length > 2)
  const label = variantLabel.toLowerCase()
  return words.some((w) => label.includes(w)) ? variantLabel : `${productName} · ${variantLabel}`
}

// [key, label, SVG path (24x24)] — rendered in the footer when a URL is set.
const FOOTER_SOCIALS = [
  ['facebook', 'Facebook', 'M9.198 21.5h4v-8.01h3.604l.396-3.98h-4V7.5a1 1 0 0 1 1-1h3v-4h-3a5 5 0 0 0-5 5v2.01h-2l-.396 3.98h2.396v8.01Z'],
  ['x', 'X', 'M18.244 2.25h3.308l-7.227 8.26 8.502 11.24H16.17l-5.214-6.817L4.99 21.75H1.68l7.73-8.835L1.254 2.25H8.08l4.713 6.231 5.45-6.231Zm-1.161 17.52h1.833L7.084 4.126H5.117L17.083 19.77Z'],
  ['instagram', 'Instagram', 'M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069ZM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0Zm0 5.838a6.162 6.162 0 1 0 0 12.324 6.162 6.162 0 0 0 0-12.324ZM12 16a4 4 0 1 1 0-8 4 4 0 0 1 0 8Zm6.406-11.845a1.44 1.44 0 1 0 0 2.881 1.44 1.44 0 0 0 0-2.881Z'],
  ['linkedin', 'LinkedIn', 'M20.447 20.452h-3.554v-5.569c0-1.328-.027-3.037-1.852-3.037-1.853 0-2.136 1.445-2.136 2.939v5.667H9.351V9h3.414v1.561h.046c.477-.9 1.637-1.85 3.37-1.85 3.601 0 4.267 2.37 4.267 5.455v6.286ZM5.337 7.433a2.062 2.062 0 0 1-2.063-2.065 2.064 2.064 0 1 1 2.063 2.065Zm1.782 13.019H3.555V9h3.564v11.452ZM22.225 0H1.771C.792 0 0 .774 0 1.729v20.542C0 23.227.792 24 1.771 24h20.451C23.2 24 24 23.227 24 22.271V1.729C24 .774 23.2 0 22.222 0h.003Z'],
  ['youtube', 'YouTube', 'M23.498 6.186a3.016 3.016 0 0 0-2.122-2.136C19.505 3.545 12 3.545 12 3.545s-7.505 0-9.377.505A3.017 3.017 0 0 0 .502 6.186C0 8.07 0 12 0 12s0 3.93.502 5.814a3.016 3.016 0 0 0 2.122 2.136c1.871.505 9.376.505 9.376.505s7.505 0 9.377-.505a3.015 3.015 0 0 0 2.122-2.136C24 15.93 24 12 24 12s0-3.93-.502-5.814ZM9.545 15.568V8.432L15.818 12l-6.273 3.568Z'],
]

const CATEGORY_EMOJI = [
  [/paan/i, '\u{1F343}'],
  [/dairy|milk|cheese|bread.*egg|egg.*bread/i, '\u{1F95B}'],
  [/fruit|vegetable|veg\b|produce/i, '\u{1F966}'],
  [/cold ?drink|soft ?drink|juice|beverage|soda|water/i, '\u{1F964}'],
  [/snack|munch|namkeen|chips|wafer/i, '\u{1F37F}'],
  [/breakfast|instant|cereal|noodle|oats/i, '\u{1F963}'],
  [/sweet|chocolate|candy|dessert|mithai/i, '\u{1F36B}'],
  [/bak|biscuit|bread|cookie|rusk/i, '\u{1F35E}'],
  [/tea|coffee|health ?drink/i, '\u{2615}'],
  [/atta|rice|dal|pulse|flour|grain|pantry|staple/i, '\u{1F35A}'],
  [/masala|spice|\boil\b|ghee|condiment/i, '\u{1F9C2}'],
  [/sauce|spread|ketchup|\bjam\b|pickle|dip/i, '\u{1F96B}'],
  [/chicken|meat|fish|seafood|poultry|mutton|egg/i, '\u{1F357}'],
  [/organic|premium|healthy living/i, '\u{1F331}'],
  [/baby/i, '\u{1F37C}'],
  [/pharma|wellness|medicine|first aid/i, '\u{1F48A}'],
  [/clean|detergent|repellent|disinfect/i, '\u{1F9FD}'],
  [/pet\b|pet ?care/i, '\u{1F43E}'],
  [/personal ?care|beauty|cosmetic|hygiene|skin|hair/i, '\u{1F9F4}'],
  [/home|office|kitchen|household|lifestyle|stationery/i, '\u{1F3E0}'],
  [/frozen/i, '\u{1F9CA}'],
]
function categoryEmoji(name = '') { return (CATEGORY_EMOJI.find(([re]) => re.test(name)) ?? [null, '\u{1F6D2}'])[1] }

const PRODUCT_EMOJI = [
  [/banana/i, '\u{1F34C}'], [/apple/i, '\u{1F34E}'], [/egg/i, '\u{1F95A}'], [/milk/i, '\u{1F95B}'],
  [/rice/i, '\u{1F35A}'], [/pasta|noodle|spaghetti/i, '\u{1F35D}'], [/bread|loaf|bun/i, '\u{1F35E}'],
  [/cheese/i, '\u{1F9C0}'], [/butter/i, '\u{1F9C8}'], [/yog[hu]|yoghurt/i, '\u{1F963}'],
  [/tomato/i, '\u{1F345}'], [/potato/i, '\u{1F954}'], [/onion|garlic/i, '\u{1F9C5}'],
  [/carrot/i, '\u{1F955}'], [/orange|citrus/i, '\u{1F34A}'], [/grape/i, '\u{1F347}'],
  [/berr|blueberr|strawberr/i, '\u{1FED0}'], [/lemon|lime/i, '\u{1F34B}'], [/avocado/i, '\u{1F951}'],
  [/chicken|poultry/i, '\u{1F357}'], [/fish|salmon|tuna/i, '\u{1F41F}'], [/coffee/i, '☕'],
  [/\btea\b/i, '\u{1F375}'], [/water/i, '\u{1F4A7}'], [/juice/i, '\u{1F9C3}'], [/oil/i, '\u{1FAD9}'],
  [/sugar/i, '\u{1F36C}'], [/salt/i, '\u{1F9C2}'], [/chocolate|cookie|biscuit/i, '\u{1F36A}'],
  [/chip|crisp/i, '\u{1F35F}'], [/corn/i, '\u{1F33D}'], [/bean|lentil/i, '\u{1FAD8}'],
  [/flour|wheat/i, '\u{1F33E}'], [/honey/i, '\u{1F36F}'], [/pepper|chil/i, '\u{1F336}️'],
  [/mushroom/i, '\u{1F344}'], [/broccoli/i, '\u{1F966}'], [/lettuce|spinach|kale|salad/i, '\u{1F96C}'],
]
function productEmoji(name = '') { return (PRODUCT_EMOJI.find(([re]) => re.test(name)) ?? [null, '\u{1F6D2}'])[1] }


const CANCELLABLE_STAGES = ['confirmed', 'packing', 'ready_for_delivery']

const ISSUE_TYPES = [
  ['item_missing', 'Item missing'],
  ['item_damaged', 'Item damaged'],
  ['wrong_item', 'Wrong item'],
  ['not_delivered', "Didn't receive order"],
  ['payment_issue', 'Payment issue'],
  ['other', 'Something else'],
]
// Not offered in the "new request" picker — only the delivery rider opens these.
const ISSUE_LABEL_EXTRA = { delivery: 'Delivery message' }
const issueLabel = (type) => ISSUE_LABEL_EXTRA[type] ?? (ISSUE_TYPES.find(([t]) => t === type) ?? [null, type])[1]

function orderLabel(order) {
  if (order.payment_status === 'refund_pending') return 'Refund pending'
  if (order.payment_status === 'refunded') return 'Refunded'
  if (order.payment_status === 'paid') return order.payment_method === 'cod' ? 'Cash collected' : 'Paid'
  if (order.payment_status === 'failed') return 'Payment failed'
  if (order.payment_status === 'cancelled') return 'Cancelled'
  if (order.payment_method === 'cod') return 'Cash on delivery'
  return 'Awaiting payment'
}

const DELIVERY_STAGES = ['confirmed', 'packing', 'ready_for_delivery', 'out_for_delivery', 'completed']
const DELIVERY_LABELS = { confirmed: 'Confirmed', packing: 'Packing', ready_for_delivery: 'Ready for delivery', out_for_delivery: 'Out for delivery', completed: 'Delivered', cancelled: 'Cancelled' }

async function responseJson(response) {
  const text = await response.text()
  const jsonStart = Math.min(...['{', '['].map((token) => {
    const index = text.indexOf(token)
    return index === -1 ? text.length : index
  }))

  return JSON.parse(text.slice(jsonStart))
}

function PaymentForm({ clientSecret, onComplete, savedCards = [] }) {
  const stripe = useStripe()
  const elements = useElements()
  const [message, setMessage] = useState('')
  const [submitting, setSubmitting] = useState(false)
  const defaultCard = savedCards.find((c) => c.is_default) ?? savedCards[0]
  const [choice, setChoice] = useState(defaultCard ? defaultCard.id : 'new') // pm id | 'new'
  const [saveCard, setSaveCard] = useState(false)
  const usingSaved = choice !== 'new'

  async function pay(event) {
    event.preventDefault()
    if (!stripe) return
    if (!usingSaved && !elements) return
    setSubmitting(true)
    setMessage('')
    const confirmData = usingSaved
      ? { payment_method: choice }
      : { payment_method: { card: elements.getElement(CardElement) }, ...(saveCard ? { setup_future_usage: 'off_session' } : {}) }
    const result = await stripe.confirmCardPayment(clientSecret, confirmData)
    if (result.error) setMessage(result.error.message)
    else if (result.paymentIntent?.status === 'succeeded') onComplete(result.paymentIntent.id)
    setSubmitting(false)
  }

  return <form className="payment-form" onSubmit={pay}>
    {savedCards.length > 0 && <div className="pay-cards" role="radiogroup" aria-label="Card">
      {savedCards.map((card) => (
        <label key={card.id} className={choice === card.id ? 'pay-card active' : 'pay-card'}>
          <input type="radio" name="paycard" checked={choice === card.id} onChange={() => setChoice(card.id)} />
          <span style={{ textTransform: 'capitalize' }}>{card.brand} &bull;&bull;&bull;&bull; {card.last4}</span>
          <em>{String(card.exp_month).padStart(2, '0')}/{String(card.exp_year).slice(-2)}</em>
        </label>
      ))}
      <label className={choice === 'new' ? 'pay-card active' : 'pay-card'}>
        <input type="radio" name="paycard" checked={choice === 'new'} onChange={() => setChoice('new')} />
        <span>Use a new card</span>
      </label>
    </div>}
    {!usingSaved && <>
      <label>Card details<CardElement options={{ style: { base: { fontSize: '16px', color: '#20291f', fontFamily: 'Manrope, sans-serif' } } }} /></label>
      <label className="account-check"><input type="checkbox" checked={saveCard} onChange={(event) => setSaveCard(event.target.checked)} /> Save this card for next time</label>
    </>}
    <button className="checkout-button" type="submit" disabled={submitting || !stripe}>{submitting ? 'Processing...' : 'Pay securely'} <span>-&gt;</span></button>
    {message && <p className="auth-message">{message}</p>}
  </form>
}

// Adds a card to the customer without charging it, via a Stripe SetupIntent.
function AddCardForm({ onDone, onCancel }) {
  const stripe = useStripe()
  const elements = useElements()
  const [message, setMessage] = useState('')
  const [busy, setBusy] = useState(false)

  async function submit(event) {
    event.preventDefault()
    if (!stripe || !elements) return
    setBusy(true)
    setMessage('')
    try {
      const res = await fetch(`${API_URL}/billing/setup-intent`, { method: 'POST', headers: { Accept: 'application/json', Authorization: `Bearer ${localStorage.getItem('gdp_token')}` } })
      const data = await res.json().catch(() => ({}))
      if (!res.ok) throw new Error(data.message ?? 'Could not start card setup.')
      const result = await stripe.confirmCardSetup(data.data.client_secret, { payment_method: { card: elements.getElement(CardElement) } })
      if (result.error) throw new Error(result.error.message)
      onDone()
    } catch (error) { setMessage(error.message) }
    setBusy(false)
  }

  return <form className="payment-form" onSubmit={submit}>
    <label>Card details<CardElement options={{ style: { base: { fontSize: '15px', color: '#20291f', fontFamily: 'Manrope, sans-serif' } } }} /></label>
    <div className="checkout-links">
      <button className="checkout-button" type="submit" disabled={busy || !stripe}>{busy ? 'Saving…' : 'Save card'}</button>
      <button className="switch-auth" type="button" onClick={onCancel}>Cancel</button>
    </div>
    {message && <p className="auth-message">{message}</p>}
  </form>
}

export default function Storefront() {
  const [categories, setCategories] = useState([])
  const [products, setProducts] = useState([])
  const [query, setQuery] = useState('')
  const [activeCategory, setActiveCategory] = useState(null)
  const [cart, setCart] = useState(() => {
    try {
      const saved = JSON.parse(localStorage.getItem('gdp_cart') ?? '[]')
      return (Array.isArray(saved) ? saved : [])
        .filter((item) => item && item.id != null)
        .map((item) => ({ variantId: null, name: '', price_cents: 0, compare_at_price_cents: null, quantity: 1, ...item, key: item.key ?? `${item.id}:${item.variantId ?? ''}` }))
    } catch { return [] }
  })
  const [pickedVariant, setPickedVariant] = useState({})
  const [loading, setLoading] = useState(true)
  const [offline, setOffline] = useState(false)
  const [pages, setPages] = useState([])
  const [pageView, setPageView] = useState(null) // { slug, title, content } | 'loading' | null
  const [location, setLocation] = useState(() => {
    try { return JSON.parse(localStorage.getItem('gdp_location') ?? 'null') }
    catch { return null }
  })
  const [locationOpen, setLocationOpen] = useState(() => {
    try { return !JSON.parse(localStorage.getItem('gdp_location') ?? 'null') }
    catch { return true }
  })
  const [editAddress, setEditAddress] = useState(false)
  const [locationQuery, setLocationQuery] = useState('')
  const [locationResults, setLocationResults] = useState([])
  const [locationBusy, setLocationBusy] = useState(false)
  const [locationMsg, setLocationMsg] = useState('')
  const [stores, setStores] = useState([])
  const [banners, setBanners] = useState([])
  const [homeTiles, setHomeTiles] = useState([])
  const [branding, setBranding] = useState(null)
  const [footer, setFooter] = useState(null)
  const mapRef = useRef(null)
  const markerRef = useRef(null)
  const mapNodeRef = useRef(null)
  const locationRef = useRef(null)
  const [cartOpen, setCartOpen] = useState(false)
  const [trayLift, setTrayLift] = useState(0) // px the cart pill is dragged up; snaps back to 0 on scroll
  const [trayDragging, setTrayDragging] = useState(false)
  const trayDragRef = useRef(null)
  const [checkoutOpen, setCheckoutOpen] = useState(false)
  const [authMode, setAuthMode] = useState(null)
  const blankAuthForm = { name: '', email: '', password: '', password_confirmation: '', line1: '', city: '', state: '', postal_code: '' }
  const [authForm, setAuthForm] = useState(blankAuthForm)
  const [otpStage, setOtpStage] = useState(null)
  const [otpCode, setOtpCode] = useState('')
  const [authTab, setAuthTab] = useState('code')
  const [authMessage, setAuthMessage] = useState('')
  const [checkoutForm, setCheckoutForm] = useState({ name: '', line1: '', city: '', state: '', postal_code: '' })
  const [deliveryNote, setDeliveryNote] = useState('')
  const [phone, setPhone] = useState('')
  const [checkoutMessage, setCheckoutMessage] = useState('')
  const [paymentMethod, setPaymentMethod] = useState('card')
  const [codEnabled, setCodEnabled] = useState(false)
  const [fees, setFees] = useState({ tax_rate_bps: 0, delivery_mode: 'fixed', delivery_fee_cents: 0, delivery_near_fee_cents: 0, delivery_far_fee_cents: 0, free_delivery_threshold_cents: 0, handling_fee_cents: 0, small_cart_fee_cents: 0, small_cart_min_cents: 0 })
  const [serviceable, setServiceable] = useState(null)
  const [order, setOrder] = useState(null)
  const [currentUser, setCurrentUser] = useState(() => {
    try {
      const saved = JSON.parse(localStorage.getItem('gdp_user') ?? 'null')
      // Ignore stale / malformed data left by an earlier version of the site.
      return saved && typeof saved === 'object' && (saved.email || saved.id) ? saved : null
    } catch { return null }
  })
  const [addresses, setAddresses] = useState([])
  const [selectedAddressId, setSelectedAddressId] = useState('')
  const [accountOpen, setAccountOpen] = useState(false)
  const [accountTab, setAccountTab] = useState('profile')
  const [accountMsg, setAccountMsg] = useState('')
  const [profileForm, setProfileForm] = useState({ name: '', phone: '' })
  const [addrForm, setAddrForm] = useState(null) // null | { id?, label, name, line1, line2, city, state, postal_code, is_default }
  const [cards, setCards] = useState(null) // null = not loaded; [] = none
  const [cardsBusy, setCardsBusy] = useState(false)
  const [addingCard, setAddingCard] = useState(false)
  const [ordersOpen, setOrdersOpen] = useState(false)
  const [orders, setOrders] = useState([])
  const [ordersLoading, setOrdersLoading] = useState(false)
  const [ordersMessage, setOrdersMessage] = useState('')
  const [supportView, setSupportView] = useState(null) // null | 'list' | 'new' | thread object
  const [threads, setThreads] = useState([])
  const [supportForm, setSupportForm] = useState({ about_order: false, order_id: '', issue_type: 'item_missing', message: '' })
  const [supportReply, setSupportReply] = useState('')
  const [supportBusy, setSupportBusy] = useState(false)
  const [supportMsg, setSupportMsg] = useState('')
  const [supportUnread, setSupportUnread] = useState(0)

  useEffect(() => {
    localStorage.setItem('gdp_cart', JSON.stringify(cart))
  }, [cart])

  // Prefill the checkout phone field from the account once it loads, without
  // clobbering anything the customer is mid-way through typing.
  useEffect(() => {
    if (currentUser?.phone) setPhone((current) => current || currentUser.phone)
  }, [currentUser])

  useEffect(() => {
    if (!checkoutOpen && !locationOpen && !accountOpen) return
    const token = localStorage.getItem('gdp_token')
    if (!token) return
    fetch(`${API_URL}/addresses`, { headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } })
      .then(responseJson)
      .then((data) => {
        setAddresses(data.data ?? [])
        if (checkoutOpen && data.data?.[0]) setSelectedAddressId(String(data.data[0].id))
      })
      .catch(() => setAddresses([]))
  }, [checkoutOpen, locationOpen, accountOpen])

  useEffect(() => {
    if (!accountOpen) return
    setAccountMsg('')
    setProfileForm({ name: currentUser?.name ?? '', phone: currentUser?.phone ?? '' })
  }, [accountOpen, currentUser])

  useEffect(() => {
    if (!accountOpen || accountTab !== 'cards' || cards !== null) return
    loadCards()
  }, [accountOpen, accountTab]) // eslint-disable-line react-hooks/exhaustive-deps

  // Have the shopper's saved cards ready when the payment step opens.
  useEffect(() => {
    if (!order?.clientSecret || !stripePromise || cards !== null) return
    loadCards()
  }, [order?.clientSecret]) // eslint-disable-line react-hooks/exhaustive-deps

  useEffect(() => {
    if (!ordersOpen) return
    const token = localStorage.getItem('gdp_token')
    if (!token) return
    fetch(`${API_URL}/orders`, { headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } })
      .then(responseJson)
      .then((data) => setOrders(data.data ?? []))
      .catch(() => setOrders([]))
      .finally(() => setOrdersLoading(false))
  }, [ordersOpen])

  useEffect(() => {
    fetch(`${API_URL}/config`, { headers: { Accept: 'application/json' } })
      .then(responseJson)
      .then((data) => { setCodEnabled(!!data.data?.cod_enabled); setStores(data.data?.stores ?? []); setBanners(data.data?.banners ?? []); setHomeTiles(data.data?.home_tiles ?? []); setBranding(data.data?.branding ?? null); setFooter(data.data?.footer ?? null); if (data.data) setFees(data.data) })
      .catch(() => { setCodEnabled(false); setStores([]); setBanners([]); setHomeTiles([]) })
  }, [])

  // Apply admin-configured branding: theme palette, accent colours, tab title
  // and favicon, all driven from GET /api/config.
  useEffect(() => {
    if (!branding) return
    const root = document.documentElement
    const s = root.style
    const dark = branding.theme === 'dark'
    s.setProperty('--paper', dark ? '#12160f' : '#f3f5f2')
    s.setProperty('--surface', dark ? '#1b211a' : '#ffffff')
    s.setProperty('--line', dark ? '#2b332a' : '#e4e8e3')
    s.setProperty('--muted', dark ? '#9aa79c' : '#6b7770')
    s.setProperty('--ink', dark ? '#eef1ec' : '#18211c')
    s.setProperty('--lime', dark ? '#1c2a1c' : '#eaf7e5')
    if (branding.color_brand) s.setProperty('--green', branding.color_brand)
    if (branding.color_accent) s.setProperty('--yellow', branding.color_accent)
    // The heading colour only overrides the theme default when it was actually customised.
    if (branding.color_heading && branding.color_heading.toLowerCase() !== '#18211c') s.setProperty('--ink', branding.color_heading)
    s.setProperty('--shell-max', branding.layout_width === 'full' ? 'none' : '1280px')
    root.style.colorScheme = dark ? 'dark' : 'light'

    const name = branding.store_name || 'Grocerly'
    document.title = branding.tagline ? `${name} | ${branding.tagline}` : name
    if (branding.favicon_url) {
      let link = document.querySelector("link[rel='icon']")
      if (!link) { link = document.createElement('link'); link.rel = 'icon'; document.head.appendChild(link) }
      link.href = mediaUrl(branding.favicon_url)
    }
  }, [branding])

  useEffect(() => { locationRef.current = location })

  // Prefill the checkout address text from the chosen location when the modal opens.
  useEffect(() => {
    if (!checkoutOpen || !location) return
    setCheckoutForm((form) => {
      if (form.line1) return form
      const line1 = location.line1 || (location.full || location.label || '').split(',').slice(0, 3).join(', ').trim()
      if (!line1 && !location.city) return form
      return {
        ...form,
        line1: line1 || form.line1,
        city: form.city || location.city || '',
        state: form.state || location.state || '',
        postal_code: form.postal_code || location.postal_code || '',
      }
    })
  }, [checkoutOpen, location])

  // Check the saved location against the store delivery radius. Runs on mount
  // for a stored location and again whenever the location's coordinates change.
  useEffect(() => {
    const lat = location?.lat
    const lng = location?.lon
    if (lat == null || lng == null) { setServiceable(null); return }
    let cancelled = false
    fetch(`${API_URL}/delivery-eta?lat=${lat}&lng=${lng}`, { headers: { Accept: 'application/json' } })
      .then(responseJson)
      .then((data) => { if (!cancelled) setServiceable(data.data ?? null) })
      .catch(() => { if (!cancelled) setServiceable(null) })
    return () => { cancelled = true }
  }, [location?.lat, location?.lon])

  useEffect(() => {
    const token = localStorage.getItem('gdp_token')
    if (!token) return
    fetch(`${API_URL}/user`, { headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } })
      .then(responseJson)
      .then((user) => { setCurrentUser(user); localStorage.setItem('gdp_user', JSON.stringify(user)) })
      .catch(() => { localStorage.removeItem('gdp_token'); localStorage.removeItem('gdp_user'); setCurrentUser(null) })
  }, [])

  // Pass the chosen location so the API can scope the catalog to the store that
  // serves this customer — a product that the nearest store doesn't stock is
  // left out. No location (or out of area) returns the full catalog.
  const catalogQuery = location?.lat != null && location?.lon != null
    ? `?lat=${location.lat}&lng=${location.lon}`
    : ''

  // Categories are a small payload and feed the homepage tiles, so fetch them
  // on their own — don't make the homepage wait on the full product list.
  useEffect(() => {
    fetch(`${API_URL}/categories${catalogQuery}`, { headers: { Accept: 'application/json' } })
      .then((response) => { if (!response.ok) throw new Error('offline'); return responseJson(response) })
      .then((data) => setCategories(data.data ?? []))
      .catch(() => { setOffline(true); setCategories(categoriesFallback) })
  }, [catalogQuery])

  useEffect(() => {
    fetch(`${API_URL}/products${catalogQuery}`, { headers: { Accept: 'application/json' } })
      .then((response) => { if (!response.ok) throw new Error('offline'); return responseJson(response) })
      .then((data) => setProducts(data.data ?? []))
      .catch(() => { setOffline(true); setProducts(fallbackProducts) })
      .finally(() => setLoading(false))
  }, [catalogQuery])

  // Content pages: load the footer list once, and keep the open page in sync
  // with a #/p/<slug> hash so links are shareable and Back works.
  useEffect(() => {
    fetch(`${API_URL}/pages`, { headers: { Accept: 'application/json' } })
      .then(responseJson).then((data) => setPages(data.data ?? [])).catch(() => setPages([]))
  }, [])

  useEffect(() => {
    const sync = () => {
      const match = window.location.hash.match(/^#\/p\/([a-z0-9-]+)$/)
      if (!match) { setPageView(null); return }
      const slug = match[1]
      setPageView((current) => (current && current.slug === slug ? current : 'loading'))
      fetch(`${API_URL}/pages/${slug}`, { headers: { Accept: 'application/json' } })
        .then(responseJson)
        .then((data) => setPageView(data.data ?? null))
        .catch(() => setPageView({ slug, title: 'Page not found', content: 'That page does not exist.' }))
    }
    sync()
    window.addEventListener('hashchange', sync)
    return () => window.removeEventListener('hashchange', sync)
  }, [])

  function openPage(slug) {
    window.location.hash = `#/p/${slug}`
    window.scrollTo({ top: 0 })
  }
  function closePage() {
    if (window.location.hash) window.location.hash = ''
    else setPageView(null)
  }

  const searching = query.trim().length > 0
  const locationUsable = !!(location && location.city && (location.line1 || location.postal_code))
  const defaultAddress = addresses.find((address) => address.is_default) ?? addresses[0] ?? null
  // How checkout resolves the delivery address, unless the user edits it:
  // the location just entered, else the account's saved address, else a form.
  const deliveryMode = editAddress ? 'form' : locationUsable ? 'location' : defaultAddress ? 'saved' : 'form'

  const outOfArea = !!(serviceable && serviceable.configured && !serviceable.deliverable)
  const needsPhone = !phone.trim()
  const blockCheckout = (outOfArea && deliveryMode === 'location') || needsPhone
  const UNSERVICEABLE_MSG = "We don't deliver to your area yet — we're expanding fast and will reach you soon."
  const etaText = serviceable?.deliverable && serviceable?.minutes
    ? `Delivery in ~${serviceable.minutes} min`
    : outOfArea ? 'Not available here yet' : 'Delivery in 12 min'

  const visibleProducts = useMemo(() => {
    const term = query.trim().toLowerCase()
    return products.filter((product) => {
      const categoryMatch = term ? true : !activeCategory || product.category?.name === activeCategory
      const textMatch = !term || [product.name, product.description, product.sku].filter(Boolean).some((value) => value.toLowerCase().includes(term))
      return categoryMatch && textMatch
    })
  }, [activeCategory, products, query])

  const categoryCounts = useMemo(() => {
    const counts = {}
    for (const product of products) {
      const name = product.category?.name
      if (name) counts[name] = (counts[name] ?? 0) + 1
    }
    return counts
  }, [products])

  // A few product names per category for the homepage feature cards.
  const categorySamples = useMemo(() => {
    const samples = {}
    for (const product of products) {
      const name = product.category?.name
      if (!name) continue
      ;(samples[name] ??= []).push(product.name)
    }
    return samples
  }, [products])

  const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0)
  const cartTotal = cart.reduce((sum, item) => sum + item.price_cents * item.quantity, 0)
  // Enrich each line with the current catalog price / discount, so the cart
  // shows sale pricing even for items added before this data existed.
  const cartView = useMemo(() => cart.map((item) => {
    const p = products.find((x) => x.id === item.id)
    const v = p && item.variantId ? (p.variants ?? []).find((x) => x.id === item.variantId) : null
    const unit = v ? v.price_cents : (p ? p.price_cents : item.price_cents)
    const regRaw = v ? v.compare_at_price_cents : (p ? p.compare_at_price_cents : item.compare_at_price_cents)
    const reg = (regRaw != null && regRaw > unit) ? regRaw : null
    return { ...item, unit, reg, onSale: reg != null, lineReg: (reg ?? unit) * item.quantity }
  }), [cart, products])
  const cartRegularTotal = cartView.reduce((sum, line) => sum + line.lineReg, 0)
  const cartQty = useMemo(() => Object.fromEntries(cart.map((item) => [item.key, item.quantity])), [cart])

  // Client-side estimate of the fee breakdown; the server total is authoritative.
  const est = useMemo(() => {
    const sub = cartTotal
    const tax = Math.round((sub * fees.tax_rate_bps) / 10000)
    // Distance mode: the fee for the current pin comes from /api/delivery-eta,
    // which re-fires as the pin moves. Otherwise the flat fee.
    const baseDelivery = fees.delivery_mode === 'distance' && serviceable?.delivery_fee_cents != null
      ? serviceable.delivery_fee_cents
      : fees.delivery_fee_cents
    const delivery = sub >= fees.free_delivery_threshold_cents ? 0 : baseDelivery
    const handling = sub > 0 ? fees.handling_fee_cents : 0
    const smallCart = sub > 0 && sub < fees.small_cart_min_cents ? fees.small_cart_fee_cents : 0
    return {
      sub, tax, delivery, handling, smallCart,
      total: sub + tax + delivery + handling + smallCart,
      toFreeDelivery: delivery > 0 ? fees.free_delivery_threshold_cents - sub : 0,
      toNoSmallCart: smallCart > 0 ? fees.small_cart_min_cents - sub : 0,
    }
  }, [cartTotal, fees, serviceable])

  function lineKey(productId, variantId) {
    return `${productId}:${variantId ?? ''}`
  }

  function add(product, variant) {
    const key = lineKey(product.id, variant?.id)
    setCart((current) => {
      const found = current.find((item) => item.key === key)
      if (found) return current.map((item) => item.key === key ? { ...item, quantity: item.quantity + 1 } : item)
      return [...current, {
        key,
        id: product.id,
        variantId: variant?.id ?? null,
        variantLabel: variant?.label ?? null,
        name: product.name,
        price_cents: variant?.price_cents ?? product.price_cents,
        compare_at_price_cents: (variant ? variant.compare_at_price_cents : product.compare_at_price_cents) ?? null,
        image_url: variant?.image_url || product.image_url,
        quantity: 1,
      }]
    })
  }

  function updateQuantity(key, amount) {
    setCart((current) => current.flatMap((item) => {
      if (item.key !== key) return [item]
      const quantity = item.quantity + amount
      return quantity > 0 ? [{ ...item, quantity }] : []
    }))
  }

  // The floating "View cart" pill can be dragged upward to reveal text it covers;
  // it slides back to its resting spot as soon as the page is scrolled.
  function trayPointerDown(event) {
    if (event.target.closest('button')) return // let the View cart tap through
    trayDragRef.current = { startY: event.clientY, base: trayLift }
    setTrayDragging(true)
    event.currentTarget.setPointerCapture?.(event.pointerId)
  }
  function trayPointerMove(event) {
    if (!trayDragRef.current) return
    const dy = event.clientY - trayDragRef.current.startY
    setTrayLift(Math.max(-320, Math.min(0, trayDragRef.current.base + dy)))
  }
  function trayPointerUp(event) {
    if (!trayDragRef.current) return
    trayDragRef.current = null
    setTrayDragging(false)
    event.currentTarget.releasePointerCapture?.(event.pointerId)
  }

  useEffect(() => {
    if (trayLift === 0) return
    const reset = () => setTrayLift(0)
    window.addEventListener('scroll', reset, { passive: true })
    return () => window.removeEventListener('scroll', reset)
  }, [trayLift])

  async function submitAuth(event) {
    event.preventDefault()
    setAuthMessage('')
    try {
      const response = await fetch(`${API_URL}/auth/start`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, body: JSON.stringify({ email: authForm.email.trim() }) })
      const data = await responseJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Please check your email.')
      if (data.token) { finishAuth(data); return }
      setOtpStage({ email: data.email, purpose: data.purpose })
      setOtpCode('')
      setAuthMessage(data.known ? 'Welcome back — enter the code we emailed you.' : 'Enter the code to finish creating your account.')
    } catch (error) {
      setAuthMessage(error instanceof TypeError ? 'The API is offline. Start Laravel on port 8000 and try again.' : error.message)
    }
  }

  async function submitPassword(event) {
    event.preventDefault()
    setAuthMessage('')
    try {
      const response = await fetch(`${API_URL}/auth/login`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, body: JSON.stringify({ email: authForm.email.trim(), password: authForm.password }) })
      const data = await responseJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'The email or password is incorrect.')
      if (data.token) { finishAuth(data); return }
      // OTP is enforced on the server — fall through to the code step.
      setOtpStage({ email: data.email, purpose: data.purpose ?? 'login' })
      setOtpCode('')
      setAuthMessage(data.message ?? 'Enter the code we emailed you to finish signing in.')
    } catch (error) {
      setAuthMessage(error instanceof TypeError ? 'The API is offline. Start Laravel on port 8000 and try again.' : error.message)
    }
  }

  function finishAuth(data) {
    // Staff accounts sign in through the dedicated /admin page, never here, so a
    // customer can't land in an admin session by typing the wrong credentials.
    if (data.user?.is_admin) {
      fetch(`${API_URL}/auth/logout`, { method: 'POST', headers: { Accept: 'application/json', Authorization: `Bearer ${data.token}` } }).catch(() => {})
      localStorage.removeItem('gdp_token')
      localStorage.removeItem('gdp_user')
      setAuthForm(blankAuthForm)
      setOtpStage(null)
      setOtpCode('')
      setAuthTab('code')
      setAuthMessage(`That's an administrator account — sign in at ${import.meta.env.BASE_URL}admin`)
      return
    }
    localStorage.setItem('gdp_token', data.token)
    localStorage.setItem('gdp_user', JSON.stringify(data.user))
    setCurrentUser(data.user)
    setAuthMessage(`Welcome, ${data.user.name}.`)
    setAuthForm(blankAuthForm)
    setAuthMode(null)
    setOtpStage(null)
    setOtpCode('')
    setAuthTab('code')
    if (cart.length) setCheckoutOpen(true)
  }

  async function submitOtp(event) {
    event.preventDefault()
    setAuthMessage('')
    try {
      const response = await fetch(`${API_URL}/auth/verify-otp`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, body: JSON.stringify({ ...otpStage, code: otpCode.trim() }) })
      const data = await responseJson(response)
      if (!response.ok) throw new Error(data.message ?? 'That code did not work.')
      finishAuth(data)
    } catch (error) {
      setAuthMessage(error instanceof TypeError ? 'The API is offline. Start Laravel on port 8000 and try again.' : error.message)
    }
  }

  async function resendOtp() {
    setAuthMessage('')
    try {
      const response = await fetch(`${API_URL}/auth/resend-otp`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, body: JSON.stringify({ ...otpStage }) })
      const data = await responseJson(response)
      setAuthMessage(data.message ?? (response.ok ? 'A new code is on its way.' : 'Could not resend the code.'))
    } catch {
      setAuthMessage('Could not resend the code.')
    }
  }

  async function logout() {
    const token = localStorage.getItem('gdp_token')
    if (token) await fetch(`${API_URL}/auth/logout`, { method: 'POST', headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } }).catch(() => {})
    localStorage.removeItem('gdp_token')
    localStorage.removeItem('gdp_user')
    setCurrentUser(null)
  }

  async function submitCheckout(event) {
    event.preventDefault()
    setCheckoutMessage('')
    const token = localStorage.getItem('gdp_token')
    if (!token) {
      setCheckoutOpen(false)
      setAuthMode('login')
      setAuthMessage('Sign in to place your order — your cart is saved.')
      return
    }

    // Pass the location so the cart's stock check reads the serving store's shelf.
    const here = location?.lat != null && location?.lon != null ? { lat: Number(location.lat), lng: Number(location.lon) } : {}
    try {
      for (const item of cart) {
        await fetch(`${API_URL}/cart/items`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ product_id: item.id, product_variant_id: item.variantId ?? null, quantity: item.quantity, ...here }) })
      }
      let checkoutBody
      if (deliveryMode !== 'location' && selectedAddressId) {
        checkoutBody = { address_id: Number(selectedAddressId) }
      } else if (deliveryMode === 'saved' && defaultAddress) {
        checkoutBody = { address_id: defaultAddress.id }
      } else {
        // Fall back to the chosen location's fields (and finally its display
        // string) so line1 is never blank even if the form wasn't touched.
        const fromFull = (location?.full || location?.label || '').split(',').slice(0, 3).join(', ').trim()
        const addressPayload = {
          ...checkoutForm,
          name: checkoutForm.name || currentUser?.name || 'Customer',
          line1: checkoutForm.line1?.trim() || location?.line1 || fromFull,
          city: checkoutForm.city || location?.city || null,
          state: checkoutForm.state || location?.state || null,
          postal_code: checkoutForm.postal_code || location?.postal_code || null,
          label: 'Home',
          is_default: addresses.length === 0,
        }
        if (!addressPayload.line1) throw new Error('Add a street / house detail for the delivery address.')
        // Carry the map pin's exact coordinates so the server checks delivery
        // against the pin, not a re-geocode of the typed address.
        if (location?.lat != null && location?.lon != null) {
          addressPayload.latitude = Number(location.lat)
          addressPayload.longitude = Number(location.lon)
        }
        const addressResponse = await fetch(`${API_URL}/addresses`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify(addressPayload) })
        const addressData = await responseJson(addressResponse)
        if (!addressResponse.ok) throw new Error(addressData.message ?? 'Address could not be saved.')
        checkoutBody = { address_id: addressData.data.id }
      }
      const method = codEnabled ? paymentMethod : 'card'
      const trimmedPhone = phone.trim()
      const response = await fetch(`${API_URL}/checkout`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ ...checkoutBody, payment_method: method, delivery_instructions: deliveryNote.trim() || null, phone: trimmedPhone }) })
      const data = await responseJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Checkout could not be completed.')
      if (trimmedPhone && currentUser && currentUser.phone !== trimmedPhone) {
        const updated = { ...currentUser, phone: trimmedPhone }
        setCurrentUser(updated)
        localStorage.setItem('gdp_user', JSON.stringify(updated))
      }
      if (method === 'cod') {
        setOrder({ ...data.data, cod: true })
      } else {
        if (!stripePromise) throw new Error('Add VITE_STRIPE_PUBLISHABLE_KEY to the web environment before paying.')
        const paymentResponse = await fetch(`${API_URL}/orders/${data.data.id}/payment-intent`, { method: 'POST', headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } })
        const paymentData = await responseJson(paymentResponse)
        if (!paymentResponse.ok) throw new Error(paymentData.message ?? 'Payment setup could not be completed.')
        setOrder({ ...data.data, clientSecret: paymentData.data.client_secret })
      }
      setCart([])
      setCartOpen(false)
      setCheckoutOpen(false)
      setCheckoutMessage('')
      setDeliveryNote('')
    } catch (error) { setCheckoutMessage(error.message) }
  }

  async function resumePayment(entry) {
    setOrdersMessage('')
    const token = localStorage.getItem('gdp_token')
    if (!token) { setOrdersMessage('Please sign in first.'); return }
    try {
      if (!stripePromise) throw new Error('Add VITE_STRIPE_PUBLISHABLE_KEY to the web environment before paying.')
      const response = await fetch(`${API_URL}/orders/${entry.id}/payment-intent`, { method: 'POST', headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } })
      const data = await responseJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Payment could not be started.')
      if (data.data.payment_status === 'paid' || !data.data.client_secret) {
        setOrders((current) => current.map((row) => row.id === entry.id ? { ...row, payment_status: 'paid', status: 'confirmed' } : row))
        return
      }
      setOrder({ ...entry, clientSecret: data.data.client_secret })
      setOrdersOpen(false)
    } catch (error) { setOrdersMessage(error.message) }
  }

  async function cancelOrder(entry) {
    if (!window.confirm(`Cancel order #${entry.id}? This can't be undone.`)) return
    setOrdersMessage('')
    const token = localStorage.getItem('gdp_token')
    if (!token) { setOrdersMessage('Please sign in first.'); return }
    try {
      const response = await fetch(`${API_URL}/orders/${entry.id}/cancel`, { method: 'POST', headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } })
      const data = await responseJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Could not cancel the order.')
      setOrders((current) => current.map((row) => row.id === entry.id ? { ...row, ...data.data } : row))
      setOrdersMessage(data.data.payment_status === 'refund_pending' ? 'Order cancelled — your refund is being processed.' : 'Order cancelled.')
    } catch (error) { setOrdersMessage(error.message) }
  }

  async function downloadReceipt(orderId) {
    setOrdersMessage('')
    const token = localStorage.getItem('gdp_token')
    if (!token) { setOrdersMessage('Please sign in first.'); return }
    try {
      const response = await fetch(`${API_URL}/orders/${orderId}/receipt`, { headers: { Accept: 'application/pdf', Authorization: `Bearer ${token}` } })
      if (response.status === 403) throw new Error('The bill is ready once payment is done — or, for cash on delivery, once the order is placed.')
      if (!response.ok) throw new Error('Could not generate the bill. Please try again.')
      const blob = await response.blob()
      const url = URL.createObjectURL(blob)
      const link = document.createElement('a')
      link.href = url
      link.download = `bill-order-${orderId}.pdf`
      document.body.appendChild(link)
      link.click()
      link.remove()
      URL.revokeObjectURL(url)
    } catch (error) { setOrdersMessage(error.message) }
  }

  const authGet = (path) => fetch(`${API_URL}${path}`, { headers: { Accept: 'application/json', Authorization: `Bearer ${localStorage.getItem('gdp_token')}` } })
  const authPost = (path, body) => fetch(`${API_URL}${path}`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json', Authorization: `Bearer ${localStorage.getItem('gdp_token')}` }, body: JSON.stringify(body) })
  const authSend = (path, method, body) => fetch(`${API_URL}${path}`, { method, headers: { 'Content-Type': 'application/json', Accept: 'application/json', Authorization: `Bearer ${localStorage.getItem('gdp_token')}` }, body: body ? JSON.stringify(body) : undefined })

  function openAccount(tab = 'profile') {
    if (!localStorage.getItem('gdp_token')) { setAuthMode('login'); setAuthMessage('Sign in to manage your account.'); return }
    setAccountTab(tab)
    setAddrForm(null)
    setAccountOpen(true)
  }

  async function saveProfile(event) {
    event.preventDefault()
    setAccountMsg('')
    try {
      const data = await responseJson(await authSend('/profile', 'PATCH', { name: profileForm.name.trim(), phone: profileForm.phone.trim() || null }))
      const updated = { ...currentUser, name: data.data?.name ?? profileForm.name, phone: data.data?.phone ?? null }
      setCurrentUser(updated)
      localStorage.setItem('gdp_user', JSON.stringify(updated))
      setAccountMsg('Profile saved.')
    } catch { setAccountMsg('Could not save your profile.') }
  }

  function reloadAddresses() {
    authGet('/addresses').then(responseJson).then((d) => setAddresses(d.data ?? [])).catch(() => {})
  }

  async function saveAddress(event) {
    event.preventDefault()
    setAccountMsg('')
    const { id, ...body } = addrForm
    body.is_default = !!addrForm.is_default
    try {
      const res = await authSend(id ? `/addresses/${id}` : '/addresses', id ? 'PATCH' : 'POST', body)
      if (!res.ok) throw new Error()
      setAddrForm(null)
      reloadAddresses()
    } catch { setAccountMsg('Could not save that address.') }
  }

  async function deleteAddress(addressId) {
    if (!window.confirm('Delete this address?')) return
    try {
      const res = await authSend(`/addresses/${addressId}`, 'DELETE')
      if (!res.ok && res.status !== 204) throw new Error()
      reloadAddresses()
    } catch { setAccountMsg('Could not delete that address.') }
  }

  async function makeDefaultAddress(addressId) {
    try {
      await authSend(`/addresses/${addressId}`, 'PATCH', { is_default: true })
      reloadAddresses()
    } catch { setAccountMsg('Could not update the default address.') }
  }

  async function loadCards() {
    setCardsBusy(true)
    try {
      const data = await responseJson(await authGet('/billing/payment-methods'))
      setCards(data.data ?? [])
    } catch { setCards([]) }
    finally { setCardsBusy(false) }
  }

  async function deleteCard(pmId) {
    if (!window.confirm('Remove this card?')) return
    setCardsBusy(true)
    try {
      const res = await authSend(`/billing/payment-methods/${pmId}`, 'DELETE')
      if (!res.ok && res.status !== 204) throw new Error()
      await loadCards()
    } catch { setAccountMsg('Could not remove that card.'); setCardsBusy(false) }
  }

  async function makeDefaultCard(pmId) {
    setCardsBusy(true)
    try {
      const res = await authSend(`/billing/payment-methods/${pmId}/default`, 'POST')
      if (!res.ok && res.status !== 204) throw new Error()
      await loadCards()
    } catch { setAccountMsg('Could not set the default card.'); setCardsBusy(false) }
  }

  async function openSupport(order) {
    if (!localStorage.getItem('gdp_token')) { setAuthMode('login'); setAuthMessage('Sign in to contact support.'); return }
    setSupportMsg('')
    setSupportView('list')
    loadThreads()
    if (!orders.length) authGet('/orders').then(responseJson).then((d) => setOrders(d.data ?? [])).catch(() => {})
    if (order) { setSupportForm({ about_order: true, order_id: String(order.id), issue_type: 'item_missing', message: '' }); setSupportView('new') }
  }

  function loadThreads() {
    authGet('/support/threads').then(responseJson).then((d) => { setThreads(d.data ?? []); markThreadsSeen(d.data ?? []) }).catch(() => {})
  }

  async function openThread(id) {
    setSupportMsg('')
    try {
      const data = await responseJson(await authGet(`/support/threads/${id}`))
      setSupportView(data.data)
      markThreadsSeen([data.data])
    } catch { setSupportMsg('Could not open that conversation.') }
  }

  async function submitSupport() {
    if (supportForm.about_order && !supportForm.order_id) { setSupportMsg('Select which order this is about.'); return }
    if (!supportForm.message.trim()) { setSupportMsg('Add a message describing the problem.'); return }
    setSupportBusy(true); setSupportMsg('')
    try {
      const body = { issue_type: supportForm.issue_type, message: supportForm.message.trim() }
      if (supportForm.about_order && supportForm.order_id) body.order_id = Number(supportForm.order_id)
      const response = await authPost('/support/threads', body)
      const data = await responseJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Could not send your request.')
      setSupportForm({ about_order: false, order_id: '', issue_type: 'item_missing', message: '' })
      setSupportView(data.data)
      loadThreads()
    } catch (error) { setSupportMsg(error.message) } finally { setSupportBusy(false) }
  }

  async function sendSupportReply() {
    const body = supportReply.trim()
    if (!body || typeof supportView !== 'object' || !supportView) return
    setSupportBusy(true)
    try {
      const response = await authPost(`/support/threads/${supportView.id}/messages`, { body })
      const data = await responseJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Message not sent.')
      setSupportReply('')
      setSupportView(data.data)
    } catch (error) { setSupportMsg(error.message) } finally { setSupportBusy(false) }
  }

  // Unread = a thread whose latest message is from staff (incl. the delivery
  // rider) and the customer hasn't opened it since. "Seen" timestamps per thread
  // live in localStorage.
  const readSeen = () => { try { return JSON.parse(localStorage.getItem('gdp_support_seen') || '{}') } catch { return {} } }
  const threadHasStaffUnread = (t, seen) => {
    const s = t.last_staff_message_at
    if (!s) return false
    if (t.last_message_at && new Date(s) < new Date(t.last_message_at)) return false // customer sent the latest
    return seen[t.id] !== s
  }
  const markThreadsSeen = (list) => {
    const seen = readSeen()
    ;(list ?? []).forEach((t) => { if (t.last_staff_message_at) seen[t.id] = t.last_staff_message_at })
    try { localStorage.setItem('gdp_support_seen', JSON.stringify(seen)) } catch { /* private mode */ }
    setSupportUnread(0)
  }

  // Background check for new staff/rider messages while the support panel is
  // closed, so the header "Help" link can show a dot.
  useEffect(() => {
    if (!currentUser) { setSupportUnread(0); return }
    let stopped = false
    const check = async () => {
      if (supportView) return // panel open — it manages "seen" itself
      try {
        const d = await responseJson(await authGet('/support/threads'))
        if (stopped) return
        const seen = readSeen()
        setSupportUnread((d.data ?? []).filter((t) => threadHasStaffUnread(t, seen)).length)
      } catch { /* keep last */ }
    }
    check()
    const timer = setInterval(check, 20000)
    return () => { stopped = true; clearInterval(timer) }
  }, [currentUser, supportView])

  // Poll the open conversation for new staff replies.
  const activeThreadId = (supportView && typeof supportView === 'object') ? supportView.id : null
  useEffect(() => {
    if (!activeThreadId) return
    const timer = setInterval(async () => {
      try {
        const response = await fetch(`${API_URL}/support/threads/${activeThreadId}`, { headers: { Accept: 'application/json', Authorization: `Bearer ${localStorage.getItem('gdp_token')}` } })
        const data = await responseJson(response)
        setSupportView((current) => (current && typeof current === 'object' && current.id === activeThreadId ? data.data : current))
      } catch { /* keep last */ }
    }, 4000)
    return () => clearInterval(timer)
  }, [activeThreadId])

  async function switchToCashOnDelivery() {
    const current = order
    const token = localStorage.getItem('gdp_token')
    if (!token || !current) return
    try {
      const response = await fetch(`${API_URL}/orders/${current.id}/payment-method`, { method: 'PATCH', headers: { 'Content-Type': 'application/json', Accept: 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ payment_method: 'cod' }) })
      const data = await responseJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Could not switch to cash on delivery.')
      setOrder({ ...current, ...data.data, clientSecret: null, cod: true })
      setCart([])
      setOrders([])
    } catch (error) { setOrder((o) => o ? { ...o, switchError: error.message } : o) }
  }

  async function finalizePayment() {
    const paid = order
    setOrder((current) => current ? { ...current, clientSecret: null, paid: true } : current)
    const token = localStorage.getItem('gdp_token')
    if (!token || !paid) return
    // Reconcile with the server so the order is confirmed even when the Stripe
    // CLI webhook listener is not running.
    await fetch(`${API_URL}/orders/${paid.id}/payment-intent`, { method: 'POST', headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } }).catch(() => {})
    setOrders([])
  }

  function applyLocation(address, { close = true } = {}) {
    setLocation(address)
    localStorage.setItem('gdp_location', JSON.stringify(address))
    // Seed the checkout address text. line1 falls back to the display name so it
    // is never blank; city/state/postcode are best-effort now.
    const line1 = address.line1 || (address.full || address.label || '').split(',').slice(0, 3).join(', ').trim()
    if (line1 || address.city || address.postal_code) {
      setCheckoutForm((form) => ({
        ...form,
        line1: line1 || form.line1,
        city: address.city || form.city,
        state: address.state || form.state,
        postal_code: address.postal_code || form.postal_code,
      }))
    }
    if (close) {
      setLocationOpen(false)
      setLocationResults([])
      setLocationQuery('')
      setLocationMsg('')
    }
  }

  // Reverse geocode a point via the backend; the returned lat/lon is forced to
  // the exact point asked for so the delivery-radius check uses it verbatim.
  async function reverseGeocode(lat, lng) {
    try {
      const data = await responseJson(await fetch(`${API_URL}/geocode/reverse?lat=${lat}&lng=${lng}`, { headers: { Accept: 'application/json' } }))
      if (data.data) return { ...data.data, lat, lon: lng }
    } catch { /* fall through to a bare pin */ }
    return { label: 'Pinned location', full: '', line1: '', city: '', state: '', postal_code: '', lat, lon: lng }
  }

  async function detectLocation() {
    setLocationMsg('')
    if (!navigator.geolocation) { setLocationMsg('This browser cannot detect location.'); return }
    setLocationBusy(true)
    navigator.geolocation.getCurrentPosition(async (pos) => {
      try {
        const { latitude, longitude } = pos.coords
        const address = await reverseGeocode(latitude, longitude)
        mapRef.current?.setView([latitude, longitude], 16)
        applyLocation(address)
      } catch {
        setLocationMsg('Could not read that location.')
      } finally {
        setLocationBusy(false)
      }
    }, (error) => {
      setLocationBusy(false)
      setLocationMsg(error.code === 1 ? 'Location permission was denied.' : 'Could not get your location.')
    }, { enableHighAccuracy: true, timeout: 10000 })
  }

  async function searchLocation(event) {
    event.preventDefault()
    const term = locationQuery.trim()
    if (term.length < 3) return
    setLocationBusy(true)
    setLocationMsg('')
    try {
      // Bias results to whatever the map is looking at (else the saved location),
      // so a multi-store shop finds addresses near the right city's store.
      const c = mapRef.current?.getCenter?.() ?? (locationRef.current?.lat != null ? { lat: locationRef.current.lat, lng: locationRef.current.lon } : null)
      const near = c ? `&lat=${c.lat}&lng=${c.lng}` : ''
      const data = await responseJson(await fetch(`${API_URL}/geocode/search?q=${encodeURIComponent(term)}${near}`, { headers: { Accept: 'application/json' } }))
      const results = Array.isArray(data.data) ? data.data : []
      setLocationResults(results.slice(1))
      if (!results.length) {
        setLocationMsg('No match for that address — drop the pin on the map instead.')
      } else {
        // Jump the map and pin straight to the best match; the user fine-tunes
        // by dragging, or picks one of the other matches below.
        mapRef.current?.setView([Number(results[0].lat), Number(results[0].lon)], 16)
        applyLocation(results[0], { close: false })
      }
    } catch {
      setLocationMsg('Address lookup is unavailable right now.')
    } finally {
      setLocationBusy(false)
    }
  }

  // Build the Leaflet map while the location modal is open. Leaflet and its CSS
  // are loaded on demand so they stay out of the initial bundle.
  useEffect(() => {
    if (!locationOpen) return
    let cancelled = false
    ;(async () => {
      const [{ default: L }] = await Promise.all([
        import('leaflet'),
        import('leaflet/dist/leaflet.css'),
      ])
      if (cancelled || !mapNodeRef.current || mapRef.current) return

      const [icon2x, icon1x, shadow] = await Promise.all([
        import('leaflet/dist/images/marker-icon-2x.png'),
        import('leaflet/dist/images/marker-icon.png'),
        import('leaflet/dist/images/marker-shadow.png'),
      ])
      const icon = L.icon({
        iconRetinaUrl: icon2x.default, iconUrl: icon1x.default, shadowUrl: shadow.default,
        iconSize: [25, 41], iconAnchor: [12, 41], popupAnchor: [1, -34], shadowSize: [41, 41],
      })

      const loc = locationRef.current
      const firstStore = stores.find((s) => s.latitude != null && s.longitude != null)
      const start = loc?.lat != null && loc?.lon != null
        ? [Number(loc.lat), Number(loc.lon)]
        : firstStore ? [Number(firstStore.latitude), Number(firstStore.longitude)] : [20, 0]

      const map = L.map(mapNodeRef.current, { zoomControl: true, scrollWheelZoom: false }).setView(start, (loc?.lat != null || firstStore) ? 14 : 2)
      mapRef.current = map
      L.tileLayer('https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png', {
        maxZoom: 19, attribution: '&copy; OpenStreetMap contributors',
      }).addTo(map)

      stores.forEach((s) => {
        if (s.latitude == null || s.longitude == null) return
        L.circle([Number(s.latitude), Number(s.longitude)], {
          radius: Number(s.delivery_radius_km) * 1000, color: '#3f7d43', weight: 1, fillColor: '#3f7d43', fillOpacity: 0.06,
        }).addTo(map)
      })

      const marker = L.marker(start, { draggable: true, icon }).addTo(map)
      markerRef.current = marker
      const pick = (latlng) => {
        marker.setLatLng(latlng)
        setLocationMsg('')
        reverseGeocode(latlng.lat, latlng.lng).then((address) => applyLocation(address, { close: false }))
      }
      marker.on('dragend', () => pick(marker.getLatLng()))
      map.on('click', (event) => pick(event.latlng))
      setTimeout(() => map.invalidateSize(), 0)
    })()

    return () => {
      cancelled = true
      if (mapRef.current) { mapRef.current.remove(); mapRef.current = null; markerRef.current = null }
    }
  }, [locationOpen, stores])

  // Keep the map marker on the current location (search jump, detect, saved address).
  useEffect(() => {
    if (!mapRef.current || !markerRef.current || location?.lat == null || location?.lon == null) return
    const point = [Number(location.lat), Number(location.lon)]
    markerRef.current.setLatLng(point)
    mapRef.current.setView(point, Math.max(mapRef.current.getZoom(), 15))
  }, [location?.lat, location?.lon])

  // A banner or homepage tile: an in-app category link wins, else a custom URL.
  function openHomeTarget(target) {
    if (target.category_slug) {
      const cat = categories.find((c) => c.slug === target.category_slug)
      if (cat) { setActiveCategory(cat.name); setQuery(''); window.scrollTo({ top: 0, behavior: 'smooth' }); return }
    }
    if (target.link_url) window.open(target.link_url, '_blank', 'noopener')
  }

  // Curated homepage tiles when an admin has set them; otherwise every category.
  const catBySlug = Object.fromEntries(categories.map((c) => [c.slug, c]))
  const homeTileList = homeTiles.length
    ? homeTiles
    : categories.map((c) => ({ id: `cat-${c.id}`, title: c.name, image_url: c.image_url, category_slug: c.slug, link_url: null }))
  const tileMeta = (tile) => {
    const name = tile.category_slug ? catBySlug[tile.category_slug]?.name : null
    return {
      label: tile.title || name || 'Shop',
      count: name ? (categoryCounts[name] ?? 0) : null,
      samples: name ? (categorySamples[name] ?? []) : [],
    }
  }

  return <><div className="app-shell">
    <header className="topbar">
      <div className="topbar-row">
        <a className="brand" href={import.meta.env.BASE_URL || '/'} aria-label={`${branding?.store_name || 'Grocerly'} home`}>{branding?.logo_url
          ? <img className="brand-logo" src={mediaUrl(branding.logo_url)} alt={branding?.store_name || 'Grocerly'} />
          : <><span className="brand-mark">{(branding?.store_name || 'g').trim().charAt(0).toLowerCase() || 'g'}</span>{(branding?.store_name || 'grocerly').toLowerCase()}</>}</a>
        <button className="deliver-to" type="button" onClick={() => { setLocationOpen(true); setLocationMsg('') }}><span className="deliver-eta">{etaText}</span><strong>{location ? location.label : 'Set your location'} <em aria-hidden>&#9662;</em></strong></button>
        <div className="topbar-actions">
          {currentUser ? <>
            <button className="link-btn" type="button" onClick={() => { setOrdersOpen(true); setOrdersLoading(true); setOrders([]); setOrdersMessage('') }}>Orders</button>
            <button className="link-btn" type="button" onClick={() => openAccount('profile')}>Account</button>
            <button className={supportUnread ? 'link-btn has-dot' : 'link-btn'} type="button" onClick={() => openSupport()}>Help{supportUnread ? <span className="link-dot" aria-label={`${supportUnread} new message${supportUnread === 1 ? '' : 's'}`} /> : null}</button>
            {currentUser.is_admin && <button className="link-btn" type="button" onClick={() => { window.location.href = `${import.meta.env.BASE_URL}admin` }}>Admin</button>}
            {currentUser.is_rider && <button className="link-btn" type="button" onClick={() => { window.location.href = `${import.meta.env.BASE_URL}rider` }}>Deliveries</button>}
            <button className="link-btn" type="button" onClick={logout}>{(currentUser.name || currentUser.email || 'Account').split(' ')[0]} &middot; Log out</button>
          </> : <button className="link-btn" type="button" onClick={() => { setAuthMode('login'); setAuthMessage('') }}>Sign in</button>}
          <button className="cart-pill" type="button" onClick={() => setCartOpen(true)} aria-label={`Cart with ${cartCount} items`}><span aria-hidden>&#128722;</span> <b>{cartCount}</b></button>
        </div>
      </div>
      <label className="searchbar"><span aria-hidden>&#8981;</span><input aria-label="Search groceries" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search for milk, bananas, bread…" /></label>
    </header>
    <main className="catalog">
      {pageView ? (() => {
        const withSections = pageView !== 'loading' && Array.isArray(pageView.sections) && pageView.sections.length > 0
        const hasBanner = pageView !== 'loading' && !!pageView.banner_image
        return (
        <article className={`page-view${withSections ? ' page-view-wide' : (hasBanner ? ' has-banner' : '')}`}>
          <button type="button" className="page-back" onClick={closePage}>&larr; Back to shopping</button>
          {pageView === 'loading'
            ? <div className="empty-state">Loading…</div>
            : <>{pageView.banner_image
                ? <div className="page-hero"><img src={mediaUrl(pageView.banner_image)} alt="" /><h1>{pageView.title}</h1></div>
                : <h1>{pageView.title}</h1>}{withSections
                ? <div className="page-sections">{pageView.sections.map((section, index) => <PageSection key={index} section={section} />)}</div>
                : <div className="page-content" dangerouslySetInnerHTML={{ __html: renderMarkdown(pageView.content) }} />}</>}
        </article>
        )
      })() : <>
      {offline && <div className="api-note">Showing sample products while the API is offline.</div>}
      {outOfArea && <div className="area-note">{UNSERVICEABLE_MSG}</div>}

      {(!searching && !activeCategory) ? (
        <>
          {loading && banners.length === 0 && homeTileList.length === 0 && <div className="empty-state">Loading…</div>}
          {banners.length > 0 && (() => {
            const heroBanners = banners.filter((b) => b.placement !== 'strip')
            const stripBanners = banners.filter((b) => b.placement === 'strip')
            return (heroBanners.length > 0 || stripBanners.length > 0) && <section className="home-banners" aria-label="Offers">
              {heroBanners.map((banner) => <button className="home-hero" type="button" key={banner.id} onClick={() => openHomeTarget(banner)}>
                <img src={mediaUrl(banner.image_url)} alt={banner.headline || 'Featured offer'} loading="eager" />
              </button>)}
              {stripBanners.length > 0 && <div className="home-strip">
                {stripBanners.map((banner) => <button className="home-strip-card" type="button" key={banner.id} onClick={() => openHomeTarget(banner)}>
                  <img src={mediaUrl(banner.image_url)} alt={banner.headline || 'Offer'} loading="lazy" />
                </button>)}
              </div>}
            </section>
          })()}

          {homeTileList.length > 0 && <section className="home-cats" aria-label="Shop by category">
            {homeTileList.map((tile) => { const meta = tileMeta(tile); return <button className="home-cat" type="button" key={tile.id} onClick={() => openHomeTarget(tile)}>
              <span className="home-cat-img" aria-hidden>{categoryEmoji(meta.label)}{tile.image_url && <img src={mediaUrl(tile.image_url)} alt="" loading="lazy" onError={(event) => { event.currentTarget.style.display = 'none' }} />}</span>
              {!tile.image_url && <span className="home-cat-label">{meta.label}</span>}
            </button> })}
          </section>}
        </>
      ) : loading ? <div className="empty-state">Loading…</div> : (
        <>
          <nav className="cat-rail" aria-label="Product categories">
            <button className="cat-tile" type="button" onClick={() => { setActiveCategory(null); setQuery('') }}><span className="cat-ico" aria-hidden>&#8592;</span>All</button>
            {categories.map((category) => <button className={activeCategory === category.name ? 'cat-tile active' : 'cat-tile'} type="button" key={category.id} onClick={() => { setActiveCategory(category.name); setQuery('') }}><span className="cat-ico" aria-hidden>{categoryEmoji(category.name)}{category.image_url && <img src={mediaUrl(category.image_url)} alt="" loading="lazy" onError={(event) => { event.currentTarget.style.display = 'none' }} />}</span>{category.name}</button>)}
          </nav>
          <div className="catalog-head"><h2>{searching ? `Results for “${query.trim()}”` : activeCategory}</h2><span>{visibleProducts.length} items</span></div>
          <div className="product-grid">{visibleProducts.map((product) => {
            const variants = product.variants ?? []
            const hasVariants = variants.length > 0
            // The plain product is always the first ("base") option.
            const options = hasVariants
              ? [{ id: '', label: product.name, price_cents: product.price_cents, compare_at_price_cents: product.compare_at_price_cents, inventory_quantity: product.inventory_quantity, image_url: product.image_url }, ...variants]
              : []
            const chosen = hasVariants
              ? (options.find((o) => String(o.id) === String(pickedVariant[product.id] ?? '')) ?? options[0])
              : null
            const variant = chosen && chosen.id !== '' ? chosen : null
            const unitPrice = chosen ? chosen.price_cents : product.price_cents
            const compareAt = chosen ? chosen.compare_at_price_cents : product.compare_at_price_cents
            const onSale = compareAt != null && compareAt > unitPrice
            const pctOff = onSale ? Math.round((1 - unitPrice / compareAt) * 100) : 0
            const stock = chosen ? chosen.inventory_quantity : product.inventory_quantity
            const key = lineKey(product.id, variant?.id)
            const qty = cartQty[key] ?? 0
            const img = (chosen?.image_url) || product.image_url
            return <article className={stock === 0 ? 'pcard sold-out' : 'pcard'} key={product.id}>
              <div className="pcard-img" aria-hidden>{stock === 0 && <span className="pcard-oos">Out of stock</span>}{onSale && stock !== 0 && <span className="pcard-off">{pctOff}% off</span>}{productEmoji(product.name)}{img && <img src={mediaUrl(img)} alt="" loading="lazy" onError={(event) => { event.currentTarget.style.display = 'none' }} />}</div>
              <p className="pcard-cat">{product.category?.name ?? 'Grocery'}</p>
              <h3>{variantTitle(product.name, variant?.label)}</h3>
              {hasVariants && <select className="pcard-variant" aria-label={`${product.name} option`} value={String(chosen?.id ?? '')} onChange={(event) => setPickedVariant((current) => ({ ...current, [product.id]: event.target.value }))}>{options.map((o) => <option key={o.id === '' ? 'base' : o.id} value={String(o.id)}>{o.label} — {price(o.price_cents)}</option>)}</select>}
              <div className="pcard-foot"><span className="pcard-price">{onSale ? <><strong className="on-sale">{price(unitPrice)}</strong><s>{price(compareAt)}</s></> : <strong>{price(unitPrice)}</strong>}</span>{qty === 0
                ? <button className="add-btn" type="button" disabled={stock === 0} onClick={() => add(product, variant)}>{stock === 0 ? 'OUT' : 'ADD'}</button>
                : <span className="stepper"><button type="button" aria-label="Remove one" onClick={() => updateQuantity(key, -1)}>&minus;</button><b>{qty}</b><button type="button" aria-label="Add one" disabled={stock != null && qty >= stock} onClick={() => updateQuantity(key, 1)}>+</button></span>}</div>
            </article>
          })}{!visibleProducts.length && <p className="empty-state">Nothing here yet.</p>}</div>
        </>
      )}
      </>}
    </main>
    {cartCount > 0 && <aside className={`cart-tray${trayDragging ? ' dragging' : ''}`} aria-live="polite" style={{ transform: `translateX(-50%) translateY(${trayLift}px)` }} onPointerDown={trayPointerDown} onPointerMove={trayPointerMove} onPointerUp={trayPointerUp} onPointerCancel={trayPointerUp}><div><strong>{cartCount} {cartCount === 1 ? 'item' : 'items'} in your cart</strong><span>{price(cartTotal)} subtotal</span></div><button type="button" onClick={() => setCartOpen(true)}>View cart <span>-&gt;</span></button></aside>}
    {cartOpen && <div className="overlay" role="presentation" onClick={() => setCartOpen(false)}><aside className="drawer" role="dialog" aria-modal="true" aria-labelledby="cart-title" onClick={(event) => event.stopPropagation()}><div className="drawer-header"><div><p className="eyebrow">Ready when you are</p><h2 id="cart-title">Your cart</h2></div><button className="close-button" type="button" onClick={() => setCartOpen(false)} aria-label="Close cart">x</button></div>{cart.length ? <><div className="drawer-items">{cartView.map((item) => <div className="drawer-item" key={item.key}><div className="mini-visual" aria-hidden>{productEmoji(item.name)}{item.image_url && <img src={mediaUrl(item.image_url)} alt="" loading="lazy" onError={(event) => { event.currentTarget.style.display = 'none' }} />}</div><div className="drawer-item-copy"><strong>{variantTitle(item.name, item.variantLabel)}</strong><span>{item.onSale ? <><strong className="on-sale">{price(item.unit)}</strong> <s>{price(item.reg)}</s></> : price(item.unit)}{item.quantity > 1 && <> &middot; {item.quantity} pcs = {item.onSale ? <><strong className="on-sale">{price(item.unit * item.quantity)}</strong> <s>{price(item.lineReg)}</s></> : price(item.unit * item.quantity)}</>}</span></div><div className="quantity"><button type="button" onClick={() => updateQuantity(item.key, -1)}>-</button><span>{item.quantity}</span><button type="button" onClick={() => updateQuantity(item.key, 1)}>+</button></div></div>)}</div><div className="drawer-summary"><div><span>Subtotal</span><span>{cartRegularTotal > est.sub ? <><s className="on-sale">{price(cartRegularTotal)}</s> {price(est.sub)}</> : price(est.sub)}</span></div><div><span>Delivery</span><span>{est.delivery === 0 ? 'FREE' : price(est.delivery)}</span></div><div><span>Handling</span><span>{price(est.handling)}</span></div>{est.smallCart > 0 && <div><span>Small cart fee</span><span>{price(est.smallCart)}</span></div>}<div><span>Tax</span><span>{price(est.tax)}</span></div><div className="drawer-summary-total"><strong>Estimated total</strong><strong>{price(est.total)}</strong></div></div>{fees.delivery_mode === 'distance' && serviceable?.delivery_fee_cents == null && <p className="drawer-nudge">Delivery fee is based on distance — set your location for the exact amount.</p>}{est.toFreeDelivery > 0 && <p className="drawer-nudge">Add {price(est.toFreeDelivery)} more for free delivery.</p>}{est.toNoSmallCart > 0 && <p className="drawer-nudge">Add {price(est.toNoSmallCart)} more to drop the {price(est.smallCart)} small-cart fee.</p>}<button className="checkout-button" type="button" onClick={() => { setCartOpen(false); setCheckoutOpen(true); setCheckoutMessage('') }}>Continue to checkout <span>-&gt;</span></button></> : <div className="empty-cart"><div className="empty-cart-mark">+</div><h3>Your cart is empty</h3><p>Find something good in the essentials below.</p><button type="button" onClick={() => setCartOpen(false)}>Keep shopping</button></div>}</aside></div>}
    {authMode && <div className="overlay" role="presentation" onClick={() => { setAuthMode(null); setOtpStage(null); setAuthTab('code') }}><div className="auth-modal" role="dialog" aria-modal="true" aria-labelledby="auth-title" onClick={(event) => event.stopPropagation()}><button className="close-button" type="button" onClick={() => { setAuthMode(null); setOtpStage(null); setAuthTab('code') }} aria-label="Close authentication">x</button><p className="eyebrow">A better grocery run</p>{otpStage ? <><h2 id="auth-title">Enter your code</h2><p className="auth-intro">We emailed a 6-digit code to {otpStage.email}. It expires in 10 minutes.</p><form onSubmit={submitOtp}><input required inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]*" maxLength="8" placeholder="6-digit code" value={otpCode} onChange={(event) => setOtpCode(event.target.value.replace(/[^0-9]/g, ''))} /><button className="checkout-button" type="submit">Verify <span>-&gt;</span></button></form>{authMessage && <p className="auth-message">{authMessage}</p>}<button className="switch-auth" type="button" onClick={resendOtp}>Resend code</button><button className="switch-auth" type="button" onClick={() => { setOtpStage(null); setAuthMessage('') }}>Use a different email</button></> : <><h2 id="auth-title">Sign in or sign up</h2><div className="auth-tabs" role="tablist"><button type="button" role="tab" aria-selected={authTab === 'code'} className={authTab === 'code' ? 'auth-tab active' : 'auth-tab'} onClick={() => { setAuthTab('code'); setAuthMessage('') }}>Email code</button><button type="button" role="tab" aria-selected={authTab === 'password'} className={authTab === 'password' ? 'auth-tab active' : 'auth-tab'} onClick={() => { setAuthTab('password'); setAuthMessage('') }}>Password</button></div>{authTab === 'password' ? <><p className="auth-intro">Already have a password? Sign in with your email and password.</p><form onSubmit={submitPassword}><input required type="email" autoComplete="email" placeholder="Email address" value={authForm.email} onChange={(event) => setAuthForm({ ...authForm, email: event.target.value })} /><input required type="password" autoComplete="current-password" placeholder="Password" value={authForm.password} onChange={(event) => setAuthForm({ ...authForm, password: event.target.value })} /><button className="checkout-button" type="submit">Sign in <span>-&gt;</span></button></form></> : <><p className="auth-intro">Enter your email and we&rsquo;ll send a 6-digit code. No password needed &mdash; if you&rsquo;re new, your account is created automatically.</p><form onSubmit={submitAuth}><input required type="email" autoComplete="email" placeholder="Email address" value={authForm.email} onChange={(event) => setAuthForm({ ...authForm, email: event.target.value })} /><button className="checkout-button" type="submit">Continue <span>-&gt;</span></button></form></>}{authMessage && <p className="auth-message">{authMessage}</p>}</>}</div></div>}
    {checkoutOpen && <div className="overlay" role="presentation" onClick={() => setCheckoutOpen(false)}><div className="auth-modal checkout-modal" role="dialog" aria-modal="true" aria-labelledby="checkout-title" onClick={(event) => event.stopPropagation()}><button className="close-button" type="button" onClick={() => setCheckoutOpen(false)} aria-label="Close checkout">x</button><p className="eyebrow">Almost there</p><h2 id="checkout-title">{deliveryMode === 'form' ? 'Where should we deliver?' : 'Confirm delivery address'}</h2><p className="auth-intro">Your total will be calculated and confirmed securely by the server.</p>{deliveryMode === 'location' ? <><div className="loc-current"><strong>Deliver to</strong> {location.full || location.label}</div><input placeholder="Flat / house / building &amp; street" value={checkoutForm.line1} onChange={(event) => setCheckoutForm({ ...checkoutForm, line1: event.target.value })} /><div className="checkout-links"><button type="button" className="switch-auth" onClick={() => { setCheckoutOpen(false); setLocationOpen(true) }}>Change location</button><button type="button" className="switch-auth" onClick={() => setEditAddress(true)}>Edit full address</button></div></> : deliveryMode === 'saved' ? <><div className="loc-current"><strong>Deliver to</strong> {defaultAddress.line1}, {defaultAddress.city} {defaultAddress.state} {defaultAddress.postal_code}</div>{addresses.length > 1 && <label className="address-picker">Choose address<select value={selectedAddressId || String(defaultAddress.id)} onChange={(event) => setSelectedAddressId(event.target.value)}>{addresses.map((address) => <option key={address.id} value={address.id}>{address.label} - {address.line1}, {address.city}</option>)}</select></label>}<div className="checkout-links"><button type="button" className="switch-auth" onClick={() => { setCheckoutOpen(false); setLocationOpen(true) }}>Change location</button><button type="button" className="switch-auth" onClick={() => { setSelectedAddressId(''); setEditAddress(true) }}>Enter a new address</button></div></> : <>{addresses.length > 0 && <label className="address-picker">Saved address<select value={selectedAddressId} onChange={(event) => setSelectedAddressId(event.target.value)}>{addresses.map((address) => <option key={address.id} value={address.id}>{address.label} - {address.line1}, {address.city}</option>)}<option value="">Use a new address</option></select></label>}<form onSubmit={submitCheckout}>{!selectedAddressId && <><input required placeholder="Full name" value={checkoutForm.name} onChange={(event) => setCheckoutForm({ ...checkoutForm, name: event.target.value })} /><input required placeholder="Street address" value={checkoutForm.line1} onChange={(event) => setCheckoutForm({ ...checkoutForm, line1: event.target.value })} /><div className="form-row"><input required placeholder="City" value={checkoutForm.city} onChange={(event) => setCheckoutForm({ ...checkoutForm, city: event.target.value })} /><input required maxLength="60" placeholder="State / region" value={checkoutForm.state} onChange={(event) => setCheckoutForm({ ...checkoutForm, state: event.target.value })} /></div><input required maxLength="12" placeholder="Postal / ZIP code" value={checkoutForm.postal_code} onChange={(event) => setCheckoutForm({ ...checkoutForm, postal_code: event.target.value })} /></>}</form></>}<label className="checkout-phone"><span>Phone number{currentUser?.phone ? '' : ' — the delivery rider may call you'}</span><input type="tel" required maxLength="32" placeholder="e.g. +1 555 987 6543" value={phone} onChange={(event) => setPhone(event.target.value)} /></label><textarea className="delivery-note" rows="2" maxLength="500" placeholder="Delivery instructions (optional) — e.g. leave at the gate, call on arrival" value={deliveryNote} onChange={(event) => setDeliveryNote(event.target.value)} />{codEnabled && <><p className="pay-methods-label">How would you like to pay?</p><div className="pay-methods" role="radiogroup" aria-label="Payment method"><button type="button" role="radio" aria-checked={paymentMethod === 'card'} className={paymentMethod === 'card' ? 'pay-method active' : 'pay-method'} onClick={() => setPaymentMethod('card')}><strong>Pay online</strong><span>Card via Stripe</span></button><button type="button" role="radio" aria-checked={paymentMethod === 'cod'} className={paymentMethod === 'cod' ? 'pay-method active' : 'pay-method'} onClick={() => setPaymentMethod('cod')}><strong>Cash on delivery</strong><span>Pay when it arrives</span></button></div></>}<button className="checkout-button" type="button" onClick={submitCheckout} disabled={blockCheckout}>{codEnabled && paymentMethod === 'cod' ? 'Place order' : 'Review order'} <span>-&gt;</span></button>{blockCheckout && <p className="auth-message">{outOfArea && deliveryMode === 'location' ? UNSERVICEABLE_MSG : 'Add a phone number so your delivery rider can reach you.'}</p>}{checkoutMessage && <p className="auth-message">{checkoutMessage}</p>}</div></div>}
    {order?.clientSecret && <div className="overlay" role="presentation" onClick={() => setOrder(null)}><div className="auth-modal checkout-modal payment-modal" role="dialog" aria-modal="true" aria-labelledby="payment-title" onClick={(event) => event.stopPropagation()}><button className="close-button" type="button" onClick={() => setOrder(null)} aria-label="Close payment">x</button><p className="eyebrow">Secure payment</p><h2 id="payment-title">Finish your order.</h2><p className="auth-intro">Order #{order.id} · {price(order.total_cents)} USD</p><Elements stripe={stripePromise}><PaymentForm clientSecret={order.clientSecret} onComplete={finalizePayment} savedCards={cards ?? []} /></Elements>{codEnabled && <button className="switch-auth" type="button" onClick={switchToCashOnDelivery}>Pay with cash on delivery instead</button>}<button className="switch-auth" type="button" onClick={() => setOrder(null)}>Pay later from Order history</button>{order.switchError && <p className="auth-message">{order.switchError}</p>}</div></div>}
    {order && !order.clientSecret && <div className="overlay" role="presentation" onClick={() => setOrder(null)}><div className="auth-modal order-modal" role="dialog" aria-modal="true" aria-labelledby="order-title" onClick={(event) => event.stopPropagation()}><p className="eyebrow">{order.cod ? 'Order confirmed' : order.paid ? 'Payment submitted' : 'Payment setup needed'}</p><h2 id="order-title">{order.cod || order.paid ? 'You’re all set.' : 'Order created.'}</h2><p className="auth-intro">{order.cod ? `Order #${order.id} is confirmed. Pay with cash when your order arrives.` : `Order #${order.id} is ${order.paid ? 'being confirmed by Stripe.' : 'waiting for Stripe test keys.'}`}</p><div className="order-breakdown"><div><span>Subtotal</span><span>{price(order.subtotal_cents)}</span></div><div><span>Delivery</span><span>{order.delivery_fee_cents === 0 ? 'FREE' : price(order.delivery_fee_cents)}</span></div><div><span>Handling</span><span>{price(order.handling_fee_cents ?? 0)}</span></div>{order.small_cart_fee_cents > 0 && <div><span>Small cart fee</span><span>{price(order.small_cart_fee_cents)}</span></div>}<div><span>Tax</span><span>{price(order.tax_cents)}</span></div></div>{order.delivery_instructions && <p className="auth-intro" style={{ margin: '12px 0 0' }}>Note to courier: &ldquo;{order.delivery_instructions}&rdquo;</p>}<div className="order-total"><span>{order.cod ? 'Pay on delivery' : 'Order total'}</span><strong>{price(order.total_cents)}</strong></div>{(order.cod || order.paid) && <button className="text-button order-receipt" type="button" onClick={() => downloadReceipt(order.id)}>Download bill (PDF)</button>}<button className="checkout-button" type="button" onClick={() => setOrder(null)}>Keep shopping <span>-&gt;</span></button>{ordersMessage && <p className="auth-message">{ordersMessage}</p>}</div></div>}
    {accountOpen && <div className="overlay" role="presentation" onClick={() => { setAccountOpen(false); setAddrForm(null) }}>
      <div className="auth-modal account-modal" role="dialog" aria-modal="true" aria-labelledby="account-title" onClick={(event) => event.stopPropagation()}>
        <button className="close-button" type="button" onClick={() => { setAccountOpen(false); setAddrForm(null) }} aria-label="Close account">x</button>
        <p className="eyebrow">Signed in as {currentUser?.email}</p>
        <h2 id="account-title">Your account</h2>
        <div className="auth-tabs" role="tablist">
          {[['profile', 'Profile'], ['addresses', 'Addresses'], ['cards', 'Payment methods']].map(([key, label]) => (
            <button key={key} type="button" role="tab" aria-selected={accountTab === key} className={accountTab === key ? 'auth-tab active' : 'auth-tab'} onClick={() => { setAccountTab(key); setAccountMsg(''); setAddrForm(null) }}>{label}</button>
          ))}
        </div>

        {accountTab === 'profile' && (
          <form className="account-form" onSubmit={saveProfile}>
            <label>Name<input required value={profileForm.name} onChange={(event) => setProfileForm({ ...profileForm, name: event.target.value })} /></label>
            <label>Phone<input type="tel" maxLength="32" placeholder="+1 555 987 6543" value={profileForm.phone} onChange={(event) => setProfileForm({ ...profileForm, phone: event.target.value })} /></label>
            {!currentUser?.is_admin && <p className="account-hint">Email is used to sign in and can&rsquo;t be changed here — contact support to update it.</p>}
            <button className="checkout-button" type="submit">Save profile</button>
          </form>
        )}

        {accountTab === 'addresses' && (addrForm ? (
          <form className="account-form" onSubmit={saveAddress}>
            <h3 className="account-sub">{addrForm.id ? 'Edit address' : 'New address'}</h3>
            <label>Label<input maxLength="40" placeholder="Home, Work…" value={addrForm.label ?? ''} onChange={(event) => setAddrForm({ ...addrForm, label: event.target.value })} /></label>
            <label>Full name<input required maxLength="120" value={addrForm.name ?? ''} onChange={(event) => setAddrForm({ ...addrForm, name: event.target.value })} /></label>
            <label>Address line 1<input required maxLength="255" value={addrForm.line1 ?? ''} onChange={(event) => setAddrForm({ ...addrForm, line1: event.target.value })} /></label>
            <label>Address line 2<input maxLength="255" value={addrForm.line2 ?? ''} onChange={(event) => setAddrForm({ ...addrForm, line2: event.target.value })} /></label>
            <div className="form-row3">
              <label>City<input maxLength="100" value={addrForm.city ?? ''} onChange={(event) => setAddrForm({ ...addrForm, city: event.target.value })} /></label>
              <label>State<input maxLength="60" value={addrForm.state ?? ''} onChange={(event) => setAddrForm({ ...addrForm, state: event.target.value })} /></label>
              <label>ZIP<input maxLength="12" value={addrForm.postal_code ?? ''} onChange={(event) => setAddrForm({ ...addrForm, postal_code: event.target.value })} /></label>
            </div>
            <label className="account-check"><input type="checkbox" checked={!!addrForm.is_default} onChange={(event) => setAddrForm({ ...addrForm, is_default: event.target.checked })} /> Use as my default address</label>
            <div className="checkout-links">
              <button className="checkout-button" type="submit">{addrForm.id ? 'Save address' : 'Add address'}</button>
              <button className="switch-auth" type="button" onClick={() => setAddrForm(null)}>Cancel</button>
            </div>
          </form>
        ) : (
          <>
            {addresses.length === 0 ? <p className="auth-intro">No saved addresses yet.</p> : <ul className="account-list">
              {addresses.map((address) => <li key={address.id} className="account-row">
                <div>
                  <strong>{address.label || 'Address'}{address.is_default && <span className="account-tag">Default</span>}</strong>
                  <span>{[address.line1, address.line2, address.city, address.state, address.postal_code].filter(Boolean).join(', ')}</span>
                </div>
                <div className="account-row-actions">
                  {!address.is_default && <button type="button" className="text-button" onClick={() => makeDefaultAddress(address.id)}>Make default</button>}
                  <button type="button" className="text-button" onClick={() => setAddrForm({ ...address })}>Edit</button>
                  <button type="button" className="text-button danger" onClick={() => deleteAddress(address.id)}>Delete</button>
                </div>
              </li>)}
            </ul>}
            <button className="checkout-button" type="button" onClick={() => setAddrForm({ label: '', name: currentUser?.name ?? '', line1: '', line2: '', city: '', state: '', postal_code: '', is_default: addresses.length === 0 })}>Add address</button>
          </>
        ))}

        {accountTab === 'cards' && (!stripePromise ? (
          <p className="auth-intro">Card management needs Stripe keys (<code>VITE_STRIPE_PUBLISHABLE_KEY</code>).</p>
        ) : addingCard ? (
          <Elements stripe={stripePromise}>
            <AddCardForm onDone={() => { setAddingCard(false); loadCards() }} onCancel={() => setAddingCard(false)} />
          </Elements>
        ) : (
          <>
            {cards === null || cardsBusy ? <p className="auth-intro">Loading cards…</p> : cards.length === 0 ? <p className="auth-intro">No saved cards yet.</p> : <ul className="account-list">
              {cards.map((card) => <li key={card.id} className="account-row">
                <div>
                  <strong style={{ textTransform: 'capitalize' }}>{card.brand} &bull;&bull;&bull;&bull; {card.last4}{card.is_default && <span className="account-tag">Default</span>}</strong>
                  <span>Expires {String(card.exp_month).padStart(2, '0')}/{String(card.exp_year).slice(-2)}</span>
                </div>
                <div className="account-row-actions">
                  {!card.is_default && <button type="button" className="text-button" disabled={cardsBusy} onClick={() => makeDefaultCard(card.id)}>Make default</button>}
                  <button type="button" className="text-button danger" disabled={cardsBusy} onClick={() => deleteCard(card.id)}>Remove</button>
                </div>
              </li>)}
            </ul>}
            <button className="checkout-button" type="button" onClick={() => setAddingCard(true)}>Add a card</button>
          </>
        ))}

        {accountMsg && <p className="auth-message">{accountMsg}</p>}
      </div>
    </div>}
    {ordersOpen && <div className="overlay" role="presentation" onClick={() => setOrdersOpen(false)}><div className="auth-modal orders-modal" role="dialog" aria-modal="true" aria-labelledby="orders-title" onClick={(event) => event.stopPropagation()}><button className="close-button" type="button" onClick={() => setOrdersOpen(false)} aria-label="Close orders">x</button><p className="eyebrow">Your grocery runs</p><h2 id="orders-title">Order history</h2>{ordersLoading ? <p className="auth-intro">Loading your orders...</p> : orders.length === 0 ? <p className="auth-intro">No orders yet. Your completed checkouts will appear here.</p> : <ul className="orders-list">{orders.map((entry) => <li className="order-row" key={entry.id}><div className="order-row-head"><strong>Order #{entry.id}</strong><span className={`order-badge order-badge-${entry.payment_status}`}>{orderLabel(entry)}</span></div><div className="order-row-meta"><span>{new Date(entry.created_at).toLocaleDateString()}</span><span>{entry.items?.length ?? 0} {entry.items?.length === 1 ? 'item' : 'items'}</span><strong>{price(entry.total_cents)}</strong></div>{(entry.payment_status === 'paid' || entry.payment_method === 'cod') && DELIVERY_STAGES.includes(entry.status) && <div className="order-track" aria-label={`Delivery status: ${DELIVERY_LABELS[entry.status]}`}>{DELIVERY_STAGES.map((stage, index) => <span key={stage} className={index <= DELIVERY_STAGES.indexOf(entry.status) ? 'track-step done' : 'track-step'} title={DELIVERY_LABELS[stage]} />)}<em>{DELIVERY_LABELS[entry.status]}</em></div>}{entry.status === 'cancelled' && <p className="order-track-note">Cancelled</p>}{entry.status === 'out_for_delivery' && entry.delivery_code && new Date(entry.delivery_code_expires_at) > new Date() && <p className="order-handover">Delivery code <b>{entry.delivery_code}</b> — read this to your rider to confirm you got the order.</p>}{entry.payment_method !== 'cod' && entry.status !== 'cancelled' && entry.payment_status !== 'paid' && entry.payment_status !== 'cancelled' && <button className="text-button order-pay" type="button" onClick={() => resumePayment(entry)}>Complete payment <span>-&gt;</span></button>}{CANCELLABLE_STAGES.includes(entry.status) && <button className="text-button order-cancel" type="button" onClick={() => cancelOrder(entry)}>Cancel order</button>}{(entry.payment_status === 'paid' || entry.payment_method === 'cod') && entry.status !== 'cancelled' && <button className="text-button order-receipt" type="button" onClick={() => downloadReceipt(entry.id)}>Download bill (PDF)</button>}<button className="text-button order-help" type="button" onClick={() => { setOrdersOpen(false); openSupport(entry) }}>Get help</button></li>)}</ul>}{ordersMessage && <p className="auth-message">{ordersMessage}</p>}</div></div>}
    {locationOpen && <div className="overlay" role="presentation" onClick={() => { if (location) setLocationOpen(false) }}><div className="auth-modal location-modal" role="dialog" aria-modal="true" aria-labelledby="loc-title" onClick={(event) => event.stopPropagation()}>{location && <button className="close-button" type="button" onClick={() => setLocationOpen(false)} aria-label="Close location">x</button>}<p className="eyebrow">Deliver to</p><h2 id="loc-title">Where are you?</h2><p className="auth-intro">Drop the pin on your building — that&rsquo;s the location we deliver to. Search or &ldquo;detect&rdquo; just move the map near your area.</p>
      {outOfArea && <p className="loc-unserviceable">{UNSERVICEABLE_MSG}</p>}
      <div className="loc-tools">
        <button className="loc-detect" type="button" onClick={detectLocation} disabled={locationBusy}>{locationBusy ? 'Locating…' : 'Detect my location'} <span aria-hidden>&#9678;</span></button>
        <form className="loc-search" onSubmit={searchLocation}><input placeholder="Search an area, road or landmark" value={locationQuery} onChange={(event) => setLocationQuery(event.target.value)} /><button type="submit" disabled={locationBusy || locationQuery.trim().length < 3}>Search</button></form>
      </div>
      {locationResults.length > 0 && <div className="loc-results"><p className="loc-saved-h">Move map to</p>{locationResults.map((place, index) => <button key={`${place.lat},${place.lon},${index}`} type="button" className="loc-result" onClick={() => { mapRef.current?.setView([Number(place.lat), Number(place.lon)], 16); applyLocation(place, { close: false }); setLocationResults([]) }}><strong>{place.label}</strong><span>{place.full}</span></button>)}</div>}
      <div ref={mapNodeRef} className="loc-map" aria-label="Pick your delivery location on the map" />
      <p className="loc-map-hint">Drag the pin to your exact door. We use the pin, not the typed address.</p>
      {location && <div className="loc-current"><strong>Pin</strong> {location.full || location.label}</div>}
      {currentUser && addresses.length > 0 && <div className="loc-saved"><p className="loc-saved-h">Saved addresses</p>{addresses.map((address) => <button key={address.id} type="button" className="loc-result" onClick={() => applyLocation({ label: `${address.label || 'Address'} · ${address.city}`, full: `${address.line1}, ${address.city} ${address.state} ${address.postal_code}`, line1: address.line1, city: address.city, state: address.state, postal_code: address.postal_code })}><strong>{address.label || 'Address'}</strong><span>{address.line1}, {address.city} {address.state} {address.postal_code}</span></button>)}</div>}
      {locationMsg && <p className="auth-message">{locationMsg}</p>}
      {location && <button className="checkout-button loc-confirm" type="button" onClick={() => { setLocationOpen(false); setLocationResults([]); setLocationQuery(''); setLocationMsg('') }}>Deliver to this location <span>-&gt;</span></button>}
    </div></div>}
    {supportView && <div className="overlay" role="presentation" onClick={() => setSupportView(null)}><div className="auth-modal support-modal" role="dialog" aria-modal="true" aria-labelledby="support-title" onClick={(event) => event.stopPropagation()}><button className="close-button" type="button" onClick={() => setSupportView(null)} aria-label="Close support">x</button><p className="eyebrow">We&rsquo;re here to help</p>
      {supportView === 'list' ? <>
        <h2 id="support-title">Support</h2>
        <button className="checkout-button" type="button" onClick={() => { setSupportForm({ about_order: false, order_id: '', issue_type: 'item_missing', message: '' }); setSupportView('new') }}>New request <span>-&gt;</span></button>
        {threads.length === 0 ? <p className="auth-intro">No conversations yet.</p> : <ul className="support-list">{threads.map((t) => <li key={t.id}><button type="button" onClick={() => openThread(t.id)}><strong>{issueLabel(t.issue_type)}{t.order_id ? ` · Order #${t.order_id}` : ''}</strong><span>{t.status === 'resolved' ? 'Resolved' : 'Open'} · {t.last_message_at ? new Date(t.last_message_at).toLocaleDateString() : ''}</span></button></li>)}</ul>}
      </> : supportView === 'new' ? <>
        <h2 id="support-title">New request</h2>
        <p className="pay-methods-label">Is this about an order?</p>
        <div className="issue-chips" role="radiogroup" aria-label="Is this about an order?">
          <button type="button" role="radio" aria-checked={!supportForm.about_order} className={!supportForm.about_order ? 'issue-chip active' : 'issue-chip'} onClick={() => setSupportForm({ ...supportForm, about_order: false, order_id: '' })}>General question</button>
          <button type="button" role="radio" aria-checked={supportForm.about_order} className={supportForm.about_order ? 'issue-chip active' : 'issue-chip'} onClick={() => setSupportForm({ ...supportForm, about_order: true })}>About an order</button>
        </div>
        {supportForm.about_order && (orders.length === 0
          ? <p className="auth-intro">You have no orders yet.</p>
          : <label className="support-field">Which order?
              <select value={supportForm.order_id} onChange={(event) => setSupportForm({ ...supportForm, order_id: event.target.value })}>
                <option value="">Select an order…</option>
                {orders.map((o) => <option key={o.id} value={o.id}>Order #{o.id} · {price(o.total_cents)}</option>)}
              </select>
            </label>)}
        <div className="issue-chips" role="radiogroup" aria-label="Issue type">{ISSUE_TYPES.map(([type, label]) => <button key={type} type="button" role="radio" aria-checked={supportForm.issue_type === type} className={supportForm.issue_type === type ? 'issue-chip active' : 'issue-chip'} onClick={() => setSupportForm({ ...supportForm, issue_type: type })}>{label}</button>)}</div>
        <textarea className="delivery-note" rows="3" maxLength="2000" placeholder="Tell us what happened" value={supportForm.message} onChange={(event) => setSupportForm({ ...supportForm, message: event.target.value })} />
        <button className="checkout-button" type="button" disabled={supportBusy} onClick={submitSupport}>Send <span>-&gt;</span></button>
        <button className="switch-auth" type="button" onClick={() => setSupportView('list')}>Back</button>
      </> : <>
        <h2 id="support-title">{issueLabel(supportView.issue_type)}{supportView.order_id ? ` · Order #${supportView.order_id}` : ''}</h2>
        {supportView.status === 'resolved' && <p className="loc-unserviceable">This conversation is resolved. Reply to re-open it.</p>}
        <div className="chat-log">{(supportView.messages ?? []).map((m) => <div key={m.id} className={`chat-msg ${m.is_staff ? 'staff' : m.user_id ? 'me' : 'system'}`}><span>{m.body}</span><em>{new Date(m.created_at).toLocaleString()}</em></div>)}</div>
        <div className="chat-send"><input placeholder="Type a message" value={supportReply} onChange={(event) => setSupportReply(event.target.value)} onKeyDown={(event) => { if (event.key === 'Enter') sendSupportReply() }} /><button type="button" disabled={supportBusy || !supportReply.trim()} onClick={sendSupportReply}>Send</button></div>
        <button className="switch-auth" type="button" onClick={() => { setSupportView('list'); loadThreads() }}>All conversations</button>
      </>}
      {supportMsg && <p className="auth-message">{supportMsg}</p>}
    </div></div>}
  </div>
  <footer className="site-footer">
    <div className="site-footer-cols">
      {(pages.some((p) => p.show_in_footer) || (footer?.links?.length ?? 0) > 0) && <div>
        <h4>Useful Links</h4>
        <ul>
          {pages.filter((p) => p.show_in_footer).map((p) => <li key={p.slug}><button type="button" onClick={() => openPage(p.slug)}>{p.title}</button></li>)}
          {(footer?.links ?? []).map((link, index) => <li key={`fl-${index}`}><a href={link.url} target="_blank" rel="noopener noreferrer">{link.label}</a></li>)}
        </ul>
      </div>}
      <div>
        <div className="site-footer-cathead"><h4>Categories</h4><button type="button" className="site-footer-seeall" onClick={() => { setActiveCategory(null); setQuery(''); closePage(); window.scrollTo({ top: 0 }) }}>see all</button></div>
        <ul className="site-footer-cats">{categories.slice(0, 24).map((c) => <li key={c.id}><button type="button" onClick={() => { closePage(); setActiveCategory(c.name); setQuery(''); window.scrollTo({ top: 0 }) }}>{c.name}</button></li>)}</ul>
      </div>
    </div>
    <div className="site-footer-bottom">
      <span className="site-footer-copy">{(footer?.copyright || '© {year} Grocerly').replace('{year}', String(new Date().getFullYear()))}</span>
      {(footer?.app_store_url || footer?.play_store_url) && <span className="site-footer-app">
        {footer?.app_store_url && <a className="app-badge" href={footer.app_store_url} target="_blank" rel="noopener noreferrer" aria-label="Download on the App Store">
          <svg viewBox="0 0 24 24" width="19" height="19" aria-hidden="true"><path fill="currentColor" d="M17.05 12.53c-.03-2.79 2.28-4.13 2.38-4.19-1.3-1.9-3.32-2.16-4.04-2.19-1.72-.17-3.35 1.01-4.22 1.01-.87 0-2.21-.99-3.63-.96-1.87.03-3.59 1.09-4.55 2.76-1.94 3.37-.5 8.36 1.39 11.09.92 1.34 2.02 2.84 3.46 2.79 1.39-.06 1.91-.9 3.59-.9 1.67 0 2.15.9 3.62.87 1.49-.03 2.44-1.37 3.36-2.71 1.06-1.56 1.5-3.07 1.52-3.15-.03-.02-2.92-1.12-2.95-4.46zM14.28 4.38c.77-.93 1.29-2.23 1.15-3.52-1.11.04-2.45.74-3.24 1.67-.71.82-1.33 2.13-1.16 3.39 1.24.1 2.5-.63 3.25-1.54z"/></svg>
          <span><small>Download on the</small><b>App Store</b></span>
        </a>}
        {footer?.play_store_url && <a className="app-badge" href={footer.play_store_url} target="_blank" rel="noopener noreferrer" aria-label="Get it on Google Play">
          <svg viewBox="0 0 24 24" width="18" height="18" aria-hidden="true">
            <path fill="#00E0FF" d="M3.3 2.06a1 1 0 0 0-.4.82v18.24a1 1 0 0 0 .4.82l10.2-9.94z"/>
            <path fill="#00E676" d="m17.53 8.53-3.42 3.33 3.42 3.33 4.06-2.35a1.02 1.02 0 0 0 0-1.96z"/>
            <path fill="#FFC107" d="M17.53 8.53 5.4 1.56a1.06 1.06 0 0 0-1.13.02l9.84 9.6z"/>
            <path fill="#FF3D47" d="M14.11 11.86 4.27 21.44a1.06 1.06 0 0 0 1.13.02l12.13-6.99z"/>
          </svg>
          <span><small>GET IT ON</small><b>Google Play</b></span>
        </a>}
      </span>}
      {FOOTER_SOCIALS.some(([key]) => footer?.socials?.[key]) && <span className="site-footer-socials">
        {FOOTER_SOCIALS.filter(([key]) => footer?.socials?.[key]).map(([key, label, path]) => (
          <a key={key} href={footer.socials[key]} target="_blank" rel="noopener noreferrer" aria-label={label}>
            <svg viewBox="0 0 24 24" width="18" height="18" fill="currentColor" aria-hidden="true"><path d={path} /></svg>
          </a>
        ))}
      </span>}
    </div>
    {footer?.note && <p className="site-footer-note">{footer.note}</p>}
  </footer>
  </>
}
