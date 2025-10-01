import Link from 'next/link'

export const metadata = {
  title: 'System Overload | GRPS Imperial Command'
}

export default function SystemOverloadPage() {
  return (
    <main className="flex min-h-[70vh] items-center justify-center px-6 py-24">
      <div className="panel max-w-3xl space-y-6 p-10 text-center">
        <p className="text-sm uppercase tracking-[0.35em] text-red-400">Critical overload</p>
        <h1 className="text-4xl font-semibold text-yellow-100" data-signal>
          503 — Systems overheating
        </h1>
        <p className="text-sm leading-relaxed text-zinc-400">
          Command relays detected a surge in leaderboard traffic and temporarily sealed outbound feeds. Operations will
          resume once the load balancers stabilise. You may still review legal directives or contact the Discord relay.
        </p>
        <div className="flex flex-wrap justify-center gap-4 text-sm">
          <Link
            href="/"
            className="rounded-full bg-yellow-500/20 px-5 py-2 font-medium text-yellow-200 transition hover:bg-yellow-500/30"
          >
            Retry command deck
          </Link>
          <Link
            href="https://discord.gg/cXKEdAKdWv"
            target="_blank"
            rel="noreferrer noopener"
            className="rounded-full bg-zinc-800 px-5 py-2 font-medium text-zinc-200 transition hover:bg-zinc-700"
          >
            Alert Discord relay
          </Link>
        </div>
      </div>
    </main>
  )
}
