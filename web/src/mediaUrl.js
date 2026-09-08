// Resolve an admin-/seeder-provided image path against the app's base path.
// Root-relative paths like "/img/pages/x.jpg" otherwise 404 when the app is
// served from a sub-folder (e.g. https://host/gdp/). Absolute URLs and data:
// URIs pass through unchanged.
const BASE = (import.meta.env.BASE_URL || '/').replace(/\/$/, '')

export function mediaUrl(url) {
  if (!url || typeof url !== 'string') return url
  if (/^(https?:)?\/\//i.test(url) || url.startsWith('data:') || url.startsWith('blob:')) return url
  return url.startsWith('/') ? BASE + url : `${BASE}/${url}`
}
