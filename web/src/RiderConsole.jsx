import { useCallback, useEffect, useRef, useState } from 'react'

const API_URL = import.meta.env.VITE_API_URL ?? 'http://127.0.0.1:8000/api'
const STORE_URL = import.meta.env.BASE_URL || '/'

const money = (c) => `$${((c ?? 0) / 100).toFixed(2)}`
const STATUS_LABEL = {
  confirmed: 'Confirmed', packing: 'Being packed', ready_for_delivery: 'Ready for pickup',
  out_for_delivery: 'Out for delivery', completed: 'Delivered', cancelled: 'Cancelled',
}
const addressText = (a) => [a?.name, a?.line1, a?.line2, [a?.city, a?.state, a?.postal_code].filter(Boolean).join(' ')].filter(Boolean).join(', ')

async function readJson(res) {
  const text = await res.text()
  try { return text ? JSON.parse(text) : {} } catch { return {} }
}

export default function RiderConsole({ token, onSignOut }) {
  const headers = useCallback((json) => ({
    Accept: 'application/json',
    Authorization: `Bearer ${token}`,
    ...(json ? { 'Content-Type': 'application/json' } : {}),
  }), [token])

  const [data, setData] = useState({ assigned: [], pool: [] })
  const [loading, setLoading] = useState(true)
  const [busyId, setBusyId] = useState(null)
  const [error, setError] = useState('')
  const [chatOrder, setChatOrder] = useState(null) // { id }
  const [chat, setChat] = useState({ messages: [], thread_id: null })
  const [reply, setReply] = useState('')
  const chatLogRef = useRef(null)

  const load = useCallback(async () => {
    try {
      const res = await fetch(`${API_URL}/rider/orders`, { headers: headers() })
      const body = await readJson(res)
      if (res.ok) { setData(body.data ?? { assigned: [], pool: [] }); setError('') }
      else setError(body.message ?? 'Could not load your deliveries.')
    } catch {
      setError('Cannot reach the server.')
    }
  }, [headers])

  useEffect(() => {
    let stop = false
    ;(async () => { await load(); if (!stop) setLoading(false) })()
    const t = setInterval(load, 15000)
    return () => { stop = true; clearInterval(t) }
  }, [load])

  async function act(order, path, bodyObj) {
    setBusyId(order.id)
    setError('')
    try {
      const res = await fetch(`${API_URL}/rider/orders/${order.id}/${path}`, {
        method: 'POST', headers: headers(true),
        body: bodyObj ? JSON.stringify(bodyObj) : undefined,
      })
      const body = await readJson(res)
      if (!res.ok) throw new Error(body.message ?? 'That action failed.')
      await load()
    } catch (e) { setError(e.message) } finally { setBusyId(null) }
  }

  // ---- chat ----
  const loadChat = useCallback(async (orderId) => {
    try {
      const res = await fetch(`${API_URL}/rider/orders/${orderId}/messages`, { headers: headers() })
      const body = await readJson(res)
      if (res.ok) setChat(body.data ?? { messages: [], thread_id: null })
    } catch { /* keep last */ }
  }, [headers])

  useEffect(() => {
    if (!chatOrder) return
    const id = chatOrder.id
    let alive = true
    const tick = () => { if (alive) loadChat(id) }
    Promise.resolve().then(tick) // off the sync effect body
    const t = setInterval(tick, 4000)
    return () => { alive = false; clearInterval(t) }
  }, [chatOrder, loadChat])

  useEffect(() => {
    if (chatLogRef.current) chatLogRef.current.scrollTop = chatLogRef.current.scrollHeight
  }, [chat])

  async function sendReply() {
    const text = reply.trim()
    if (!text || !chatOrder) return
    setReply('')
    try {
      const res = await fetch(`${API_URL}/rider/orders/${chatOrder.id}/messages`, {
        method: 'POST', headers: headers(true), body: JSON.stringify({ body: text }),
      })
      const body = await readJson(res)
      if (res.ok) setChat(body.data)
      else { setReply(text); setError(body.message ?? 'Message not sent.') }
    } catch { setReply(text); setError('Message not sent.') }
  }

  if (loading) return <div className="rider-shell"><div className="rider-loading">Loading your deliveries…</div></div>

  const OrderCard = ({ order, pool }) => {
    const a = order.delivery_address || {}
    const canStart = order.status === 'ready_for_delivery'
    const canDeliver = order.status === 'out_for_delivery'
    const preparing = order.status === 'confirmed' || order.status === 'packing'
    return (
      <article className="rider-card">
        <div className="rider-card-top">
          <strong>Order #{order.id}</strong>
          <span className={`rider-pill s-${order.status}`}>{STATUS_LABEL[order.status] ?? order.status}</span>
        </div>
        <div className="rider-card-cust">
          <span>{order.customer_name || 'Customer'}</span>
          {order.customer_phone && <a href={`tel:${order.customer_phone}`}>📞 {order.customer_phone}</a>}
        </div>
        <p className="rider-card-addr">{addressText(a)}</p>
        {order.delivery_instructions && <p className="rider-card-note">“{order.delivery_instructions}”</p>}
        <ul className="rider-card-items">
          {order.items?.map((it, i) => <li key={i}>{it.quantity} × {it.name}</li>)}
        </ul>
        {order.cod_due > 0 && <p className="rider-card-cod">Collect cash: <b>{money(order.cod_due)}</b></p>}
        <div className="rider-card-actions">
          <a className="rider-btn ghost" href={`https://www.google.com/maps/search/?api=1&query=${encodeURIComponent(addressText(a))}`} target="_blank" rel="noreferrer">Directions</a>
          <button className="rider-btn ghost" type="button" onClick={() => setChatOrder({ id: order.id })}>Message customer</button>
          {pool
            ? <button className="rider-btn" type="button" disabled={busyId === order.id} onClick={() => act(order, 'claim')}>Pick up</button>
            : <>
                {preparing && <span className="rider-wait">Waiting for the store to pack it…</span>}
                {canStart && <button className="rider-btn" type="button" disabled={busyId === order.id} onClick={() => act(order, 'status', { status: 'out_for_delivery' })}>Start delivery</button>}
                {order.cod_due > 0 && (canStart || canDeliver) && <button className="rider-btn" type="button" disabled={busyId === order.id} onClick={() => act(order, 'cash-collected')}>Cash collected</button>}
                {canDeliver && <button className="rider-btn primary" type="button" disabled={busyId === order.id} onClick={() => act(order, 'status', { status: 'completed' })}>Mark delivered</button>}
              </>}
        </div>
      </article>
    )
  }

  return (
    <div className="rider-shell">
      <header className="rider-bar">
        <strong>Deliveries</strong>
        <div>
          <button type="button" className="rider-link" onClick={load}>Refresh</button>
          <a className="rider-link" href={STORE_URL}>Store</a>
          <button type="button" className="rider-link" onClick={onSignOut}>Sign out</button>
        </div>
      </header>

      {error && <p className="rider-error">{error}</p>}

      <section className="rider-section">
        <h2>My deliveries ({data.assigned.length})</h2>
        {data.assigned.length === 0
          ? <p className="rider-empty">Nothing assigned to you right now. New assignments appear here automatically.</p>
          : data.assigned.map((o) => <OrderCard key={o.id} order={o} />)}
      </section>

      {data.pool.length > 0 && (
        <section className="rider-section">
          <h2>Available to pick up ({data.pool.length})</h2>
          {data.pool.map((o) => <OrderCard key={o.id} order={o} pool />)}
        </section>
      )}

      {chatOrder && (
        <div className="rider-chat-overlay" role="presentation" onClick={() => setChatOrder(null)}>
          <aside className="rider-chat" onClick={(e) => e.stopPropagation()}>
            <div className="rider-chat-head">
              <strong>Order #{chatOrder.id} · customer</strong>
              <button type="button" onClick={() => setChatOrder(null)}>Close</button>
            </div>
            <div className="rider-chat-log" ref={chatLogRef}>
              {chat.messages?.length
                ? chat.messages.map((m) => (
                    <div key={m.id} className={`rider-msg ${m.mine ? 'mine' : m.from}`}>
                      <span>{m.body}</span>
                      <em>{new Date(m.at).toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</em>
                    </div>
                  ))
                : <p className="rider-empty">No messages yet. Say hello to the customer.</p>}
            </div>
            <div className="rider-chat-send">
              <input placeholder="Message the customer" value={reply} onChange={(e) => setReply(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter') sendReply() }} />
              <button type="button" disabled={!reply.trim()} onClick={sendReply}>Send</button>
            </div>
          </aside>
        </div>
      )}
    </div>
  )
}
