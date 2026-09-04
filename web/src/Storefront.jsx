import { useEffect, useMemo, useState } from 'react'
import { CardElement, Elements, useElements, useStripe } from '@stripe/react-stripe-js'
import { loadStripe } from '@stripe/stripe-js'
import Admin from './Admin'
import './StorefrontBase.css'
import './Storefront.css'
import './Checkout.css'

const API_URL = 'http://127.0.0.1:8000/api'
const stripePromise = import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY ? loadStripe(import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY) : null
const fallbackProducts = [
  { id: 1, name: 'Organic Bananas', price_cents: 299, category: { name: 'Fresh Produce' } },
  { id: 2, name: 'Gala Apples', price_cents: 449, category: { name: 'Fresh Produce' } },
  { id: 3, name: 'Large Brown Eggs', price_cents: 599, category: { name: 'Dairy and Eggs' } },
  { id: 4, name: 'Whole Milk', price_cents: 429, category: { name: 'Dairy and Eggs' } },
  { id: 5, name: 'Long Grain Rice', price_cents: 699, category: { name: 'Pantry Staples' } },
  { id: 6, name: 'Pasta', price_cents: 249, category: { name: 'Pantry Staples' } },
]
const categoriesFallback = [
  { id: 1, name: 'Fresh Produce' },
  { id: 2, name: 'Dairy and Eggs' },
  { id: 3, name: 'Pantry Staples' },
]

function price(cents) { return `$${(cents / 100).toFixed(2)}` }

function orderLabel(order) {
  if (order.payment_status === 'paid') return 'Paid'
  if (order.payment_status === 'failed') return 'Payment failed'
  if (order.payment_status === 'cancelled') return 'Cancelled'
  return 'Awaiting payment'
}

const DELIVERY_STAGES = ['confirmed', 'preparing', 'out_for_delivery', 'completed']
const DELIVERY_LABELS = { confirmed: 'Confirmed', preparing: 'Preparing', out_for_delivery: 'Out for delivery', completed: 'Delivered', cancelled: 'Cancelled' }

async function responseJson(response) {
  const text = await response.text()
  const jsonStart = Math.min(...['{', '['].map((token) => {
    const index = text.indexOf(token)
    return index === -1 ? text.length : index
  }))

  return JSON.parse(text.slice(jsonStart))
}

function PaymentForm({ clientSecret, onComplete }) {
  const stripe = useStripe()
  const elements = useElements()
  const [message, setMessage] = useState('')
  const [submitting, setSubmitting] = useState(false)

  async function pay(event) {
    event.preventDefault()
    if (!stripe || !elements) return
    setSubmitting(true)
    const result = await stripe.confirmCardPayment(clientSecret, { payment_method: { card: elements.getElement(CardElement) } })
    if (result.error) setMessage(result.error.message)
    else if (result.paymentIntent?.status === 'succeeded') onComplete(result.paymentIntent.id)
    setSubmitting(false)
  }

  return <form className="payment-form" onSubmit={pay}><label>Card details<CardElement options={{ style: { base: { fontSize: '16px', color: '#20291f', fontFamily: 'Manrope, sans-serif' } } }} /></label><button className="checkout-button" type="submit" disabled={submitting || !stripe}>{submitting ? 'Processing...' : 'Pay securely'} <span>-&gt;</span></button>{message && <p className="auth-message">{message}</p>}</form>
}

export default function Storefront() {
  const [categories, setCategories] = useState([])
  const [products, setProducts] = useState([])
  const [query, setQuery] = useState('')
  const [activeCategory, setActiveCategory] = useState('All items')
  const [cart, setCart] = useState(() => {
    try { return JSON.parse(localStorage.getItem('gdp_cart') ?? '[]') }
    catch { return [] }
  })
  const [loading, setLoading] = useState(true)
  const [offline, setOffline] = useState(false)
  const [cartOpen, setCartOpen] = useState(false)
  const [checkoutOpen, setCheckoutOpen] = useState(false)
  const [authMode, setAuthMode] = useState(null)
  const blankAuthForm = { name: '', email: '', password: '', password_confirmation: '', line1: '', city: '', state: '', postal_code: '' }
  const [authForm, setAuthForm] = useState(blankAuthForm)
  const [otpStage, setOtpStage] = useState(null)
  const [otpCode, setOtpCode] = useState('')
  const [authMessage, setAuthMessage] = useState('')
  const [checkoutForm, setCheckoutForm] = useState({ name: '', line1: '', city: '', state: '', postal_code: '' })
  const [checkoutMessage, setCheckoutMessage] = useState('')
  const [order, setOrder] = useState(null)
  const [currentUser, setCurrentUser] = useState(() => {
    try { return JSON.parse(localStorage.getItem('gdp_user') ?? 'null') }
    catch { return null }
  })
  const [addresses, setAddresses] = useState([])
  const [selectedAddressId, setSelectedAddressId] = useState('')
  const [ordersOpen, setOrdersOpen] = useState(false)
  const [orders, setOrders] = useState([])
  const [ordersLoading, setOrdersLoading] = useState(false)
  const [ordersMessage, setOrdersMessage] = useState('')
  const [adminOpen, setAdminOpen] = useState(false)

  useEffect(() => {
    localStorage.setItem('gdp_cart', JSON.stringify(cart))
  }, [cart])

  useEffect(() => {
    if (!checkoutOpen) return
    const token = localStorage.getItem('gdp_token')
    if (!token) return
    fetch(`${API_URL}/addresses`, { headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } })
      .then(responseJson)
      .then((data) => {
        setAddresses(data.data ?? [])
        if (data.data?.[0]) setSelectedAddressId(String(data.data[0].id))
      })
      .catch(() => setAddresses([]))
  }, [checkoutOpen])

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
    const token = localStorage.getItem('gdp_token')
    if (!token) return
    fetch(`${API_URL}/user`, { headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } })
      .then(responseJson)
      .then((user) => { setCurrentUser(user); localStorage.setItem('gdp_user', JSON.stringify(user)) })
      .catch(() => { localStorage.removeItem('gdp_token'); localStorage.removeItem('gdp_user'); setCurrentUser(null) })
  }, [])

  useEffect(() => {
    async function loadCatalog() {
      try {
        const responses = await Promise.all([fetch(`${API_URL}/categories`), fetch(`${API_URL}/products`)] )
        if (responses.some((response) => !response.ok)) throw new Error('Catalog unavailable')
        const categoryData = await responseJson(responses[0])
        const productData = await responseJson(responses[1])
        setCategories(categoryData.data ?? [])
        setProducts(productData.data ?? [])
      } catch {
        setOffline(true)
        setCategories(categoriesFallback)
        setProducts(fallbackProducts)
      } finally { setLoading(false) }
    }
    loadCatalog()
  }, [])

  const visibleProducts = useMemo(() => {
    const term = query.trim().toLowerCase()
    return products.filter((product) => {
      const categoryMatch = activeCategory === 'All items' || product.category?.name === activeCategory
      const textMatch = !term || [product.name, product.description, product.sku].filter(Boolean).some((value) => value.toLowerCase().includes(term))
      return categoryMatch && textMatch
    })
  }, [activeCategory, products, query])

  const cartCount = cart.reduce((sum, item) => sum + item.quantity, 0)
  const cartTotal = cart.reduce((sum, item) => sum + item.price_cents * item.quantity, 0)

  function add(product) {
    setCart((current) => {
      const found = current.find((item) => item.id === product.id)
      return found ? current.map((item) => item.id === product.id ? { ...item, quantity: item.quantity + 1 } : item) : [...current, { ...product, quantity: 1 }]
    })
  }

  function updateQuantity(productId, amount) {
    setCart((current) => current.flatMap((item) => {
      if (item.id !== productId) return [item]
      const quantity = item.quantity + amount
      return quantity > 0 ? [{ ...item, quantity }] : []
    }))
  }

  async function submitAuth(event) {
    event.preventDefault()
    setAuthMessage('')
    const endpoint = authMode === 'register' ? 'register' : 'login'
    const body = authMode === 'register'
      ? { name: authForm.name, email: authForm.email, password: authForm.password, password_confirmation: authForm.password_confirmation, ...(authForm.line1 ? { address: { name: authForm.name, line1: authForm.line1, city: authForm.city, state: authForm.state, postal_code: authForm.postal_code } } : {}) }
      : { email: authForm.email, password: authForm.password }

    try {
      const response = await fetch(`${API_URL}/auth/${endpoint}`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json' }, body: JSON.stringify(body) })
      const data = await responseJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Please check your details.')
      if (data.requires_otp) {
        setOtpStage({ email: data.email, purpose: data.purpose })
        setOtpCode('')
        setAuthMessage(data.message ?? 'Enter the code we emailed you.')
        return
      }
      finishAuth(data)
    } catch (error) {
      setAuthMessage(error instanceof TypeError ? 'The API is offline. Start Laravel on port 8000 and try again.' : error.message)
    }
  }

  function finishAuth(data) {
    localStorage.setItem('gdp_token', data.token)
    localStorage.setItem('gdp_user', JSON.stringify(data.user))
    setCurrentUser(data.user)
    setAuthMessage(`Welcome, ${data.user.name}.`)
    setAuthForm(blankAuthForm)
    setAuthMode(null)
    setOtpStage(null)
    setOtpCode('')
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
    if (!token) { setCheckoutMessage('Please sign in before checking out.'); return }

    try {
      for (const item of cart) {
        await fetch(`${API_URL}/cart/items`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ product_id: item.id, quantity: item.quantity }) })
      }
      let checkoutBody
      if (selectedAddressId) {
        checkoutBody = { address_id: Number(selectedAddressId) }
      } else {
        const addressResponse = await fetch(`${API_URL}/addresses`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify({ ...checkoutForm, label: 'Home', is_default: addresses.length === 0 }) })
        const addressData = await responseJson(addressResponse)
        if (!addressResponse.ok) throw new Error(addressData.message ?? 'Address could not be saved.')
        checkoutBody = { address_id: addressData.data.id }
      }
      const response = await fetch(`${API_URL}/checkout`, { method: 'POST', headers: { 'Content-Type': 'application/json', Accept: 'application/json', Authorization: `Bearer ${token}` }, body: JSON.stringify(checkoutBody) })
      const data = await responseJson(response)
      if (!response.ok) throw new Error(data.message ?? 'Checkout could not be completed.')
      if (!stripePromise) throw new Error('Add VITE_STRIPE_PUBLISHABLE_KEY to the web environment before paying.')
      const paymentResponse = await fetch(`${API_URL}/orders/${data.data.id}/payment-intent`, { method: 'POST', headers: { Accept: 'application/json', Authorization: `Bearer ${token}` } })
      const paymentData = await responseJson(paymentResponse)
      if (!paymentResponse.ok) throw new Error(paymentData.message ?? 'Payment setup could not be completed.')
      setOrder({ ...data.data, clientSecret: paymentData.data.client_secret })
      setCart([])
      setCartOpen(false)
      setCheckoutOpen(false)
      setCheckoutMessage('')
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

  return <div className="app-shell">
    <div className="notice-bar">Free delivery on orders over $35 <span>Serving your neighborhood today</span></div>
    <header className="site-header">
      <a className="brand" href="/" aria-label="Grocerly home"><span className="brand-mark">g</span>grocerly</a>
      <div className="location">Deliver to <strong>Brooklyn, NY</strong> <span>v</span></div>
      {currentUser ? <><button className="text-button" type="button" onClick={() => { setOrdersOpen(true); setOrdersLoading(true); setOrders([]); setOrdersMessage('') }}>Your orders</button>{currentUser.is_admin && <button className="text-button" type="button" onClick={() => setAdminOpen(true)}>Admin</button>}<button className="text-button account-name" type="button" onClick={logout}>{currentUser.name} <span>Log out</span></button></> : <button className="text-button" type="button" onClick={() => { setAuthMode('login'); setAuthMessage('') }}>Sign in</button>}
      <button className="cart-button" type="button" onClick={() => setCartOpen(true)} aria-label={`Cart with ${cartCount} items`}>Cart <b>{cartCount}</b></button>
    </header>
    <main>
      <section className="hero-section">
        <div className="hero-copy"><p className="eyebrow">Freshness, delivered</p><h1>Your everyday grocery run, made easy.</h1><p className="hero-subtitle">Good food, fair prices, and a little more time in your day. Delivered when you need it.</p>
          <label className="search-box"><span>/</span><input aria-label="Search groceries" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="Search for groceries" /><kbd>Search</kbd></label>
          <div className="hero-meta"><i /> Same-day delivery <em /> No memberships</div>
        </div>
        <div className="hero-art" role="img" aria-label="Fresh groceries illustration"><div className="art-sun" /><div className="basket"><span className="leaf leaf-a" /><span className="leaf leaf-b" /><span className="fruit fruit-a" /><span className="fruit fruit-b" /><span className="fruit fruit-c" /></div><small>picked today</small></div>
      </section>
      <section className="catalog-section" aria-labelledby="catalog-title"><div className="section-heading"><div><p className="eyebrow">The good stuff</p><h2 id="catalog-title">Shop the essentials</h2></div><span className="result-count">{visibleProducts.length} items</span></div>
        <div className="category-row" aria-label="Product categories"><button className={activeCategory === 'All items' ? 'chip active' : 'chip'} type="button" onClick={() => setActiveCategory('All items')}>All items</button>{categories.map((category) => <button className={activeCategory === category.name ? 'chip active' : 'chip'} type="button" key={category.id} onClick={() => setActiveCategory(category.name)}>{category.name}</button>)}</div>
        {offline && <div className="api-note">Showing sample products while the API is offline.</div>}
        {loading ? <div className="empty-state">Loading the good stuff...</div> : <div className="product-grid">{visibleProducts.map((product) => <article className="product-card" key={product.id}><div className={`product-visual visual-${product.id % 4}`}><span>{product.name.split(' ').map((word) => word[0]).join('').slice(0, 2)}</span></div><div className="product-info"><p className="product-category">{product.category?.name ?? 'Grocery'}</p><h3>{product.name}</h3><div className="product-bottom"><strong>{price(product.price_cents)}</strong><button className="add-button" type="button" onClick={() => add(product)}>Add <span>+</span></button></div></div></article>)}</div>}
      </section>
    </main>
    <aside className="cart-tray" aria-live="polite"><div><strong>{cartCount ? `${cartCount} ${cartCount === 1 ? 'item' : 'items'} in your cart` : 'Your cart is ready'}</strong><span>{cartCount ? `${price(cartTotal)} subtotal` : 'Add something delicious'}</span></div><button type="button" onClick={() => setCartOpen(true)}>View cart <span>-&gt;</span></button></aside>
    {cartOpen && <div className="overlay" role="presentation" onClick={() => setCartOpen(false)}><aside className="drawer" role="dialog" aria-modal="true" aria-labelledby="cart-title" onClick={(event) => event.stopPropagation()}><div className="drawer-header"><div><p className="eyebrow">Ready when you are</p><h2 id="cart-title">Your cart</h2></div><button className="close-button" type="button" onClick={() => setCartOpen(false)} aria-label="Close cart">x</button></div>{cart.length ? <><div className="drawer-items">{cart.map((item) => <div className="drawer-item" key={item.id}><div className="mini-visual">{item.name.slice(0, 2)}</div><div className="drawer-item-copy"><strong>{item.name}</strong><span>{price(item.price_cents)}</span></div><div className="quantity"><button type="button" onClick={() => updateQuantity(item.id, -1)}>-</button><span>{item.quantity}</span><button type="button" onClick={() => updateQuantity(item.id, 1)}>+</button></div></div>)}</div><div className="drawer-total"><span>Subtotal</span><strong>{price(cartTotal)}</strong></div><button className="checkout-button" type="button" onClick={() => { setCartOpen(false); setCheckoutOpen(true); setCheckoutMessage('') }}>Continue to checkout <span>-&gt;</span></button></> : <div className="empty-cart"><div className="empty-cart-mark">+</div><h3>Your cart is empty</h3><p>Find something good in the essentials below.</p><button type="button" onClick={() => setCartOpen(false)}>Keep shopping</button></div>}</aside></div>}
    {authMode && <div className="overlay" role="presentation" onClick={() => { setAuthMode(null); setOtpStage(null) }}><div className="auth-modal" role="dialog" aria-modal="true" aria-labelledby="auth-title" onClick={(event) => event.stopPropagation()}><button className="close-button" type="button" onClick={() => { setAuthMode(null); setOtpStage(null) }} aria-label="Close authentication">x</button><p className="eyebrow">A better grocery run</p>{otpStage ? <><h2 id="auth-title">Enter your code</h2><p className="auth-intro">We emailed a 6-digit code to {otpStage.email}. It expires in 10 minutes.</p><form onSubmit={submitOtp}><input required inputMode="numeric" autoComplete="one-time-code" pattern="[0-9]*" maxLength="8" placeholder="6-digit code" value={otpCode} onChange={(event) => setOtpCode(event.target.value.replace(/[^0-9]/g, ''))} /><button className="checkout-button" type="submit">Verify <span>-&gt;</span></button></form>{authMessage && <p className="auth-message">{authMessage}</p>}<button className="switch-auth" type="button" onClick={resendOtp}>Resend code</button><button className="switch-auth" type="button" onClick={() => { setOtpStage(null); setAuthMessage('') }}>Use a different email</button></> : <><h2 id="auth-title">{authMode === 'register' ? 'Create your account' : 'Welcome back'}</h2><p className="auth-intro">{authMode === 'register' ? 'Save your details for a faster checkout.' : 'Sign in to pick up where you left off.'}</p><form onSubmit={submitAuth}>{authMode === 'register' && <input required placeholder="Full name" value={authForm.name} onChange={(event) => setAuthForm({ ...authForm, name: event.target.value })} />}<input required type="email" placeholder="Email address" value={authForm.email} onChange={(event) => setAuthForm({ ...authForm, email: event.target.value })} /><input required minLength="8" type="password" placeholder="Password" value={authForm.password} onChange={(event) => setAuthForm({ ...authForm, password: event.target.value })} />{authMode === 'register' && <input required minLength="8" type="password" placeholder="Confirm password" value={authForm.password_confirmation} onChange={(event) => setAuthForm({ ...authForm, password_confirmation: event.target.value })} />}<button className="checkout-button" type="submit">{authMode === 'register' ? 'Create account' : 'Sign in'} <span>-&gt;</span></button></form>{authMessage && <p className="auth-message">{authMessage}</p>}<button className="switch-auth" type="button" onClick={() => { setAuthMode(authMode === 'register' ? 'login' : 'register'); setAuthMessage('') }}>{authMode === 'register' ? 'Already have an account? Sign in' : 'New here? Create an account'}</button></>}</div></div>}
    {checkoutOpen && <div className="overlay" role="presentation" onClick={() => setCheckoutOpen(false)}><div className="auth-modal checkout-modal" role="dialog" aria-modal="true" aria-labelledby="checkout-title" onClick={(event) => event.stopPropagation()}><button className="close-button" type="button" onClick={() => setCheckoutOpen(false)} aria-label="Close checkout">x</button><p className="eyebrow">Almost there</p><h2 id="checkout-title">Where should we deliver?</h2><p className="auth-intro">Your total will be calculated and confirmed securely by the server.</p>{addresses.length > 0 && <label className="address-picker">Saved address<select value={selectedAddressId} onChange={(event) => setSelectedAddressId(event.target.value)}>{addresses.map((address) => <option key={address.id} value={address.id}>{address.label} - {address.line1}, {address.city}</option>)}<option value="">Use a new address</option></select></label>}<form onSubmit={submitCheckout}>{!selectedAddressId && <><input required placeholder="Full name" value={checkoutForm.name} onChange={(event) => setCheckoutForm({ ...checkoutForm, name: event.target.value })} /><input required placeholder="Street address" value={checkoutForm.line1} onChange={(event) => setCheckoutForm({ ...checkoutForm, line1: event.target.value })} /><div className="form-row"><input required placeholder="City" value={checkoutForm.city} onChange={(event) => setCheckoutForm({ ...checkoutForm, city: event.target.value })} /><input required maxLength="2" placeholder="State" value={checkoutForm.state} onChange={(event) => setCheckoutForm({ ...checkoutForm, state: event.target.value.toUpperCase() })} /></div><input required pattern="[0-9]{5}(-[0-9]{4})?" placeholder="ZIP code" value={checkoutForm.postal_code} onChange={(event) => setCheckoutForm({ ...checkoutForm, postal_code: event.target.value })} /></>}</form><button className="checkout-button" type="button" onClick={submitCheckout}>Review order <span>-&gt;</span></button>{checkoutMessage && <p className="auth-message">{checkoutMessage}</p>}</div></div>}
    {order?.clientSecret && <div className="overlay" role="presentation"><div className="auth-modal checkout-modal payment-modal" role="dialog" aria-modal="true" aria-labelledby="payment-title"><p className="eyebrow">Secure payment</p><h2 id="payment-title">Finish your order.</h2><p className="auth-intro">Order #{order.id} · {price(order.total_cents)} USD</p><Elements stripe={stripePromise}><PaymentForm clientSecret={order.clientSecret} onComplete={finalizePayment} /></Elements></div></div>}
    {order && !order.clientSecret && <div className="overlay" role="presentation" onClick={() => setOrder(null)}><div className="auth-modal order-modal" role="dialog" aria-modal="true" aria-labelledby="order-title" onClick={(event) => event.stopPropagation()}><p className="eyebrow">{order.paid ? 'Payment submitted' : 'Payment setup needed'}</p><h2 id="order-title">{order.paid ? 'You’re all set.' : 'Order created.'}</h2><p className="auth-intro">Order #{order.id} is {order.paid ? 'being confirmed by Stripe.' : 'waiting for Stripe test keys.'}</p><div className="order-total"><span>Order total</span><strong>{price(order.total_cents)}</strong></div><button className="checkout-button" type="button" onClick={() => setOrder(null)}>Keep shopping <span>-&gt;</span></button></div></div>}
    {ordersOpen && <div className="overlay" role="presentation" onClick={() => setOrdersOpen(false)}><div className="auth-modal orders-modal" role="dialog" aria-modal="true" aria-labelledby="orders-title" onClick={(event) => event.stopPropagation()}><button className="close-button" type="button" onClick={() => setOrdersOpen(false)} aria-label="Close orders">x</button><p className="eyebrow">Your grocery runs</p><h2 id="orders-title">Order history</h2>{ordersLoading ? <p className="auth-intro">Loading your orders...</p> : orders.length === 0 ? <p className="auth-intro">No orders yet. Your completed checkouts will appear here.</p> : <ul className="orders-list">{orders.map((entry) => <li className="order-row" key={entry.id}><div className="order-row-head"><strong>Order #{entry.id}</strong><span className={`order-badge order-badge-${entry.payment_status}`}>{orderLabel(entry)}</span></div><div className="order-row-meta"><span>{new Date(entry.created_at).toLocaleDateString()}</span><span>{entry.items?.length ?? 0} {entry.items?.length === 1 ? 'item' : 'items'}</span><strong>{price(entry.total_cents)}</strong></div>{entry.payment_status === 'paid' && DELIVERY_STAGES.includes(entry.status) && <div className="order-track" aria-label={`Delivery status: ${DELIVERY_LABELS[entry.status]}`}>{DELIVERY_STAGES.map((stage, index) => <span key={stage} className={index <= DELIVERY_STAGES.indexOf(entry.status) ? 'track-step done' : 'track-step'} title={DELIVERY_LABELS[stage]} />)}<em>{DELIVERY_LABELS[entry.status]}</em></div>}{entry.payment_status === 'paid' && entry.status === 'cancelled' && <p className="order-track-note">Cancelled</p>}{entry.status !== 'cancelled' && entry.payment_status !== 'paid' && entry.payment_status !== 'cancelled' && <button className="text-button order-pay" type="button" onClick={() => resumePayment(entry)}>Complete payment <span>-&gt;</span></button>}</li>)}</ul>}{ordersMessage && <p className="auth-message">{ordersMessage}</p>}</div></div>}
    {adminOpen && currentUser?.is_admin && <Admin token={localStorage.getItem('gdp_token')} onClose={() => setAdminOpen(false)} />}
    <footer><span>grocerly</span><span>Fresh food. Less fuss.</span><span>USD / United States</span></footer>
  </div>
}
