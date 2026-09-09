import { lazy, Suspense } from 'react'
import Storefront from './Storefront'

// The admin console lives at its own URL (BASE + "admin", e.g. /gdp/admin) so
// staff credentials are never entered on the shopper sign-in. A hash (#/admin)
// works too where path rewrites aren't available.
const base = import.meta.env.BASE_URL || '/'
const path = window.location.pathname.replace(/\/$/, '')
const adminPath = `${base}admin`.replace(/\/$/, '')
const isAdminRoute = path === adminPath || window.location.hash === '#/admin'

// The admin bundle (console + charts + map) is a separate chunk — shoppers never
// download it, and an admin refresh doesn't pull in the whole storefront.
const AdminEntry = lazy(() => import('./AdminEntry'))

function App() {
  if (!isAdminRoute) return <Storefront />
  return (
    <Suspense fallback={<div style={{ padding: 40, font: '14px system-ui, sans-serif', color: '#555' }}>Loading admin…</div>}>
      <AdminEntry />
    </Suspense>
  )
}

export default App
