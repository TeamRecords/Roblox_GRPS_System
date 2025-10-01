import Link from 'next/link'

export const metadata = {
  title: 'Security Lockdown | GRPS Imperial Command'
}

export default function SecurityLockdownPage() {
  return (
    <main className="flex min-h-[70vh] items-center justify-center px-6 py-24">
      <div className="panel-emphasis max-w-3xl space-y-6 p-10 text-center">
        <p className="text-sm uppercase tracking-[0.35em] text-yellow-400">Lockdown engaged</p>
        <h1 className="text-4xl font-semibold text-yellow-100" data-signal>
          401 — Clearance required
        </h1>
        <p className="text-sm leading-relaxed text-zinc-400">
          The imperial firewall blocked this path until your credentials are re-authorised. Reconnect through the Discord
          relay or return to the command deck to request elevated access.
        </p>
        <div className="flex flex-wrap justify-center gap-4 text-sm">
          <Link
            href="/"
            className="rounded-full bg-yellow-500/20 px-5 py-2 font-medium text-yellow-200 transition hover:bg-yellow-500/30"
          >
            Return to command deck
          </Link>
          <Link
            href="https://discord.gg/cXKEdAKdWv"
            target="_blank"
            rel="noreferrer noopener"
            className="rounded-full bg-zinc-800 px-5 py-2 font-medium text-zinc-200 transition hover:bg-zinc-700"
          >
            Request clearance
          </Link>
        </div>
      </div>
    </main>
  )
}
