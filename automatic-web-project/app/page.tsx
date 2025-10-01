import Link from 'next/link'

export default function Home() {
  return (
    <main>
      <section className="mx-auto flex max-w-3xl flex-col gap-6 rounded-2xl bg-slate-900/60 p-10 shadow-xl ring-1 ring-slate-800">
        <header className="space-y-2">
          <h1 className="text-3xl font-bold tracking-tight text-slate-50">Automation API Console</h1>
          <p className="text-slate-300">
            This deployment powers the Robloxian Lightning Empire GRPS automation layer and exposes the live API routes consumed
            by the public web portal.
          </p>
        </header>
        <div className="grid gap-4 md:grid-cols-2">
          <Link
            href="/api/leaderboard/top"
            className="rounded-lg border border-slate-700 bg-slate-800/70 p-4 transition hover:border-emerald-400 hover:bg-slate-800"
          >
            <h2 className="text-lg font-semibold text-slate-100">Leaderboard Top</h2>
            <p className="text-sm text-slate-400">JSON payload consumed by the public ranking board.</p>
          </Link>
          <Link
            href="/api/leaderboard/records"
            className="rounded-lg border border-slate-700 bg-slate-800/70 p-4 transition hover:border-emerald-400 hover:bg-slate-800"
          >
            <h2 className="text-lg font-semibold text-slate-100">Records Snapshot</h2>
            <p className="text-sm text-slate-400">Top KOs and WOs aggregated from the automation datastore.</p>
          </Link>
          <Link
            href="/api/metrics/health"
            className="rounded-lg border border-slate-700 bg-slate-800/70 p-4 transition hover:border-emerald-400 hover:bg-slate-800"
          >
            <h2 className="text-lg font-semibold text-slate-100">Automation Metrics</h2>
            <p className="text-sm text-slate-400">Operational metrics for observability dashboards.</p>
          </Link>
          <Link
            href="/api/health/live"
            className="rounded-lg border border-slate-700 bg-slate-800/70 p-4 transition hover:border-emerald-400 hover:bg-slate-800"
          >
            <h2 className="text-lg font-semibold text-slate-100">Health Check</h2>
            <p className="text-sm text-slate-400">Status endpoint used by uptime monitors.</p>
          </Link>
        </div>
        <p className="text-xs uppercase tracking-widest text-slate-500">
          Deployment domain: <span className="font-semibold text-emerald-300">automation.arcfoundation.net</span>
        </p>
      </section>
    </main>
  )
}
