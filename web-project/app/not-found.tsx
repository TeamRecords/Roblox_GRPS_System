import Link from 'next/link'

export default function NotFound() {
  return (
    <main className="flex min-h-[70vh] items-center justify-center px-6 py-24">
      <div className="panel-emphasis max-w-2xl p-10 text-center">
        <p className="text-sm uppercase tracking-[0.35em] text-zinc-500">Signal lost</p>
        <h1 className="mt-6 text-5xl font-semibold text-yellow-100" data-signal>
          404 — Sector not mapped
        </h1>
        <p className="mt-4 text-sm leading-relaxed text-zinc-400">
          The requested transmission fell outside the mapped command grid. Return to the command deck or inspect our legal
          directives to remain in compliance with the Roblox empire.
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-4 text-sm">
          <Link
            href="/"
            className="rounded-full bg-yellow-500/20 px-5 py-2 font-medium text-yellow-200 transition hover:bg-yellow-500/30"
          >
            Back to command deck
          </Link>
          <Link
            href="/errors/overload"
            className="rounded-full bg-zinc-800 px-5 py-2 font-medium text-zinc-200 transition hover:bg-zinc-700"
          >
            View system status
          </Link>
        </div>
      </div>
    </main>
  )
}
