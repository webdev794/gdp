// Tiny dependency-free SVG charts for the admin dashboard.

const PALETTE = [
  '#3f7d43', '#6aa84f', '#b6d7a8', '#e69138', '#cc7a29',
  '#8a6d2f', '#7c857a', '#c27ba0', '#5b9aa0', '#a64d79',
]
const color = (index) => PALETTE[index % PALETTE.length]

const TAU = Math.PI * 2
const START = -Math.PI / 2

// data: [{ label, value }]
export function PieChart({ data, size = 168 }) {
  const slices = (data ?? []).filter((d) => d.value > 0)
  const total = slices.reduce((sum, d) => sum + d.value, 0)
  const r = size / 2

  if (!total) return <p className="chart-empty">No orders in this range.</p>

  // Cumulative value before each slice — built immutably so nothing is
  // reassigned inside the render callbacks.
  const before = slices.reduce((acc, slice) => [...acc, acc[acc.length - 1] + slice.value], [0])

  const paths = slices.map((slice, index) => {
    if (slices.length === 1) {
      return <circle key={slice.label} cx={r} cy={r} r={r} fill={color(index)} />
    }
    const a0 = START + (before[index] / total) * TAU
    const a1 = START + (before[index + 1] / total) * TAU
    const large = a1 - a0 > Math.PI ? 1 : 0
    const d = [
      `M ${r} ${r}`,
      `L ${r + r * Math.cos(a0)} ${r + r * Math.sin(a0)}`,
      `A ${r} ${r} 0 ${large} 1 ${r + r * Math.cos(a1)} ${r + r * Math.sin(a1)}`,
      'Z',
    ].join(' ')
    return <path key={slice.label} d={d} fill={color(index)} />
  })

  return (
    <div className="chart-pie">
      <svg viewBox={`0 0 ${size} ${size}`} width={size} height={size} role="img" aria-label="Breakdown">
        {paths}
      </svg>
      <ul className="chart-legend">
        {slices.map((slice, index) => (
          <li key={slice.label}>
            <i style={{ background: color(index) }} />
            {slice.label} <b>{slice.value}</b>
            <span>{Math.round((slice.value / total) * 100)}%</span>
          </li>
        ))}
      </ul>
    </div>
  )
}

// Period-over-period change badge. "Up" is treated as good (green).
export function Delta({ current, previous }) {
  if (!previous) {
    if (!current) return <span className="delta flat">no change</span>
    return <span className="delta up">▲ new</span>
  }
  const pct = Math.round(((current - previous) / previous) * 100)
  if (pct === 0) return <span className="delta flat">0%</span>
  const dir = pct > 0 ? 'up' : 'down'
  return <span className={`delta ${dir}`}>{pct > 0 ? '▲' : '▼'} {Math.abs(pct)}%</span>
}

// Paired bars per bucket: previous vs current. data: [{ label, a, b }]
export function GroupedBars({ data, format = (v) => v, height = 220, legend }) {
  const rows = data ?? []
  const max = Math.max(1, ...rows.flatMap((row) => [row.a, row.b]))
  const showEvery = rows.length > 14 ? Math.ceil(rows.length / 9) : 1

  if (!rows.length) return <p className="chart-empty">No data.</p>

  return (
    <div className="chart-bars" style={{ height }}>
      <div className="chart-bars-head">
        <span className="chart-bars-max">{format(max)}</span>
        {legend && (
          <span className="chart-inline-legend">
            <i className="sw prev" />{legend.a}<i className="sw now" />{legend.b}
          </span>
        )}
      </div>
      <div className="chart-bars-plot">
        {rows.map((row, index) => (
          <div className="chart-bar-col" key={row.label + index}
            title={`${row.label}\n${legend?.a ?? 'previous'}: ${format(row.a)}\n${legend?.b ?? 'current'}: ${format(row.b)}`}>
            <div className="grouped-pair">
              <div className="chart-bar prev" style={{ height: `${(row.a / max) * 100}%` }} />
              <div className="chart-bar now" style={{ height: `${(row.b / max) * 100}%` }} />
            </div>
            <span className="chart-bar-label">{index % showEvery === 0 ? row.label : ''}</span>
          </div>
        ))}
      </div>
    </div>
  )
}

// series: [{ label, value }]; format: fn(value) -> string
export function BarChart({ series, format = (v) => v, height = 190 }) {
  const rows = series ?? []
  const max = Math.max(1, ...rows.map((row) => row.value))
  const showEvery = rows.length > 16 ? Math.ceil(rows.length / 8) : 1

  if (!rows.length) return <p className="chart-empty">No data.</p>

  return (
    <div className="chart-bars" style={{ height }}>
      <div className="chart-bars-max">{format(max)}</div>
      <div className="chart-bars-plot">
        {rows.map((row, index) => (
          <div className="chart-bar-col" key={row.label + index} title={`${row.label}: ${format(row.value)}`}>
            <div className="chart-bar" style={{ height: `${(row.value / max) * 100}%` }}>
              <span className="chart-bar-val">{row.value ? format(row.value) : ''}</span>
            </div>
            <span className="chart-bar-label">{index % showEvery === 0 ? row.label : ''}</span>
          </div>
        ))}
      </div>
    </div>
  )
}
