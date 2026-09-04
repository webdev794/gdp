import { useCallback, useEffect, useState } from 'react'
import './Admin.css'

const API_URL = 'http://127.0.0.1:8000/api'

const money = (cents) => `$${((cents ?? 0) / 100).toFixed(2)}`

const STATUS_LABELS = {
  pending_payment: 'Awaiting payment',
  confirmed: 'Confirmed',
  preparing: 'Preparing',
  out_for_delivery: 'Out for delivery',
  completed: 'Delivered',
  cancelled: 'Cancelled',
}

const NEXT_ACTIONS = {
  confirmed: [['preparing', 'Start preparing'], ['cancelled', 'Cancel']],
  preparing: [['out_for_delivery', 'Send out for delivery'], ['cancelled', 'Cancel']],
  out_for_delivery: [['completed', 'Mark delivered']],
  completed: [],
  cancelled: [],
}

const STATUS_FILTERS = ['all', 'confirmed', 'preparing', 'out_for_delivery', 'completed', 'cancelled']
const TABS = ['dashboard', 'orders', 'products', 'categories', 'customers']

const EMPTY_PRODUCT = { category_id: '', name: '', sku: '', price: '', inventory_quantity: 0, description: '', is_active: true }
const EMPTY_CATEGORY = { name: '', slug: '', sort_order: 0, is_active: true }

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
  const [metrics, setMetrics] = useState(null)
  const [orders, setOrders] = useState([])
  const [products, setProducts] = useState([])
  const [categories, setCategories] = useState([])
  const [customers, setCustomers] = useState([])
  const [customerDetail, setCustomerDetail] = useState(null)
  const [statusFilter, setStatusFilter] = useState('all')
  const [productSearch, setProductSearch] = useState('')
  const [productForm, setProductForm] = useState(null)
  const [categoryForm, setCategoryForm] = useState(null)
  const [courierDraft, setCourierDraft] = useState({})
  const [busyId, setBusyId] = useState(null)
  const [message, setMessage] = useState('')

  const authHeaders = useCallback(() => ({ Accept: 'application/json', Authorization: `Bearer ${token}` }), [token])
  const jsonHeaders = useCallback(() => ({ ...authHeaders(), 'Content-Type': 'application/json' }), [authHeaders])

  const fail = (error) => setMessage(error?.message ?? 'Something went wrong.')

  const loadMetrics = useCallback(() => {
    fetch(`${API_URL}/admin/metrics`, { headers: authHeaders() }).then(readJson)
      .then((data) => setMetrics(data.data)).catch(() => setMessage('Could not load dashboard metrics.'))
  }, [authHeaders])

  const loadOrders = useCallback(() => {
    const query = statusFilter === 'all' ? '' : `?status=${statusFilter}`
    fetch(`${API_URL}/admin/orders${query}`, { headers: authHeaders() }).then(readJson)
      .then((data) => setOrders(data.data ?? [])).catch(() => setMessage('Could not load orders.'))
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

  useEffect(() => { loadMetrics() }, [loadMetrics])
  useEffect(() => { if (tab === 'orders') loadOrders() }, [tab, loadOrders])
  useEffect(() => { if (tab === 'products') { loadProducts(); loadCategories() } }, [tab, loadProducts, loadCategories])
  useEffect(() => { if (tab === 'categories') loadCategories() }, [tab, loadCategories])
  useEffect(() => { if (tab === 'customers') loadCustomers() }, [tab, loadCustomers])

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

  async function saveProduct(event) {
    event.preventDefault()
    setMessage('')
    const { id, price, ...rest } = productForm
    const payload = { ...rest, category_id: Number(rest.category_id), inventory_quantity: Number(rest.inventory_quantity), price_cents: Math.round(Number(price) * 100) }
    try {
      const response = await fetch(`${API_URL}/admin/products${id ? `/${id}` : ''}`, { method: id ? 'PATCH' : 'POST', headers: jsonHeaders(), body: JSON.stringify(payload) })
      const data = await readJson(response)
      if (!response.ok) throw new Error(data.message ?? Object.values(data.errors ?? {})[0]?.[0] ?? 'Could not save the product.')
      setProductForm(null)
      loadProducts()
      loadMetrics()
    } catch (error) { fail(error) }
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

  return (
    <div className="admin-shell">
      <header className="admin-bar">
        <div className="admin-brand"><span>g</span> Admin console</div>
        <nav className="admin-tabs">
          {TABS.map((name) => (
            <button key={name} type="button" className={tab === name ? 'active' : ''} onClick={() => { setTab(name); setMessage('') }}>{name}</button>
          ))}
        </nav>
        <button className="admin-close" type="button" onClick={onClose}>Back to store</button>
      </header>

      {message && <p className="admin-message">{message}</p>}

      {tab === 'dashboard' && (
        <section className="admin-grid">
          {!metrics ? <p className="admin-empty">Loading metrics...</p> : (
            <>
              <article className="metric"><span>Paid revenue</span><strong>{money(metrics.revenue_cents)}</strong></article>
              <article className="metric"><span>Orders</span><strong>{metrics.orders_total}</strong></article>
              <article className="metric"><span>Awaiting fulfilment</span><strong>{metrics.awaiting_fulfilment}</strong></article>
              <article className="metric"><span>Customers</span><strong>{metrics.customers}</strong></article>
              <article className="metric"><span>Products</span><strong>{metrics.products}</strong></article>
              <article className="metric"><span>Low stock (&le;5)</span><strong>{metrics.low_stock}</strong></article>
              <article className="metric wide">
                <span>Orders by status</span>
                <div className="metric-breakdown">
                  {Object.entries(metrics.orders_by_status ?? {}).map(([status, count]) => (
                    <em key={status}>{STATUS_LABELS[status] ?? status}: <b>{count}</b></em>
                  ))}
                </div>
              </article>
            </>
          )}
        </section>
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
              <thead><tr><th>#</th><th>Customer</th><th>Placed</th><th>Items</th><th>Total</th><th>Payment</th><th>Delivery</th><th>Courier</th><th>Actions</th></tr></thead>
              <tbody>
                {orders.map((order) => (
                  <tr key={order.id}>
                    <td>{order.id}</td>
                    <td>{order.user?.email ?? '—'}</td>
                    <td>{new Date(order.created_at).toLocaleDateString()}</td>
                    <td>{order.items?.length ?? 0}</td>
                    <td>{money(order.total_cents)}</td>
                    <td><span className={`pill pill-${order.payment_status}`}>{order.payment_status}</span></td>
                    <td>{STATUS_LABELS[order.status] ?? order.status}</td>
                    <td className="admin-courier">
                      <input value={courierDraft[order.id] ?? order.courier_name ?? ''} placeholder="Unassigned"
                        onChange={(event) => setCourierDraft((current) => ({ ...current, [order.id]: event.target.value }))} />
                      <button type="button" disabled={busyId === order.id} onClick={() => patchOrder(order, { courier_name: (courierDraft[order.id] ?? order.courier_name ?? '').trim() || null })}>Save</button>
                    </td>
                    <td className="admin-actions">
                      {(NEXT_ACTIONS[order.status] ?? []).length === 0 && <span className="muted">—</span>}
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
              <label>Description<textarea rows="2" value={productForm.description ?? ''} onChange={(event) => setProductForm({ ...productForm, description: event.target.value })} /></label>
              <div className="admin-form-actions">
                <button className="act" type="submit">Save</button>
                <button className="act ghost" type="button" onClick={() => setProductForm(null)}>Cancel</button>
              </div>
            </form>
          )}

          {products.length === 0 ? <p className="admin-empty">No products.</p> : (
            <table className="admin-table">
              <thead><tr><th>Name</th><th>SKU</th><th>Category</th><th>Price</th><th>Stock</th><th>Active</th><th></th></tr></thead>
              <tbody>
                {products.map((product) => (
                  <tr key={product.id}>
                    <td>{product.name}</td>
                    <td>{product.sku}</td>
                    <td>{product.category?.name ?? '—'}</td>
                    <td>{money(product.price_cents)}</td>
                    <td className={product.inventory_quantity <= 5 ? 'low' : ''}>{product.inventory_quantity}</td>
                    <td>{product.is_active ? 'Yes' : 'No'}</td>
                    <td className="admin-actions">
                      <button className="act" type="button" onClick={() => setProductForm({ id: product.id, category_id: product.category_id, name: product.name, sku: product.sku, price: (product.price_cents / 100).toFixed(2), inventory_quantity: product.inventory_quantity, description: product.description ?? '', is_active: product.is_active })}>Edit</button>
                      <button className="act danger" type="button" onClick={() => removeProduct(product)}>Delete</button>
                    </td>
                  </tr>
                ))}
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

      {customerDetail && (
        <div className="admin-drawer" role="presentation" onClick={() => setCustomerDetail(null)}>
          <aside onClick={(event) => event.stopPropagation()}>
            <button className="admin-close" type="button" onClick={() => setCustomerDetail(null)}>Close</button>
            {customerDetail.loading ? <p className="admin-empty">Loading…</p> : (
              <>
                <h3>{customerDetail.name}</h3>
                <p className="muted">{customerDetail.email} · joined {new Date(customerDetail.joined_at).toLocaleDateString()}</p>
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
