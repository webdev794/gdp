import Storefront from './Storefront'
import AdminEntry from './AdminEntry'

// The admin console lives at its own URL (BASE + "admin", e.g. /gdp/admin) so
// staff credentials are never entered on the shopper sign-in. A hash (#/admin)
// works too where path rewrites aren't available.
const base = import.meta.env.BASE_URL || '/'
const path = window.location.pathname.replace(/\/$/, '')
const adminPath = `${base}admin`.replace(/\/$/, '')
const isAdminRoute = path === adminPath || window.location.hash === '#/admin'

function App() {
  return isAdminRoute ? <AdminEntry /> : <Storefront />
}

export default App
