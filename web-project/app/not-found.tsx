import Link from 'next/link'

export default function NotFound() {
  return (
    <main className="flex min-h-[70vh] items-center justify-center px-6 py-24">
      <div className="max-w-xl text-center">
        <div className="mx-auto flex h-24 w-24 items-center justify-center rounded-3xl bg-gradient-to-br from-blue-500 to-violet-500 text-3xl font-bold text-white shadow-xl">
          404
        </div>
        <h1 className="mt-8 text-4xl font-semibold text-white">Page not found</h1>
        <p className="mt-4 text-sm text-slate-300">
          The page you&apos;re looking for doesn&apos;t exist or has been moved. Explore the latest leaderboard standings or
          head to our legal center for more information.
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-4 text-sm">
          <Link
            href="/"
            className="rounded-full border border-white/10 bg-white/10 px-5 py-2 font-medium text-white shadow-lg transition hover:bg-white/20"
          >
            Back to leaderboard
          </Link>
          <Link
            href="/legal/leaderstats-rules"
            className="rounded-full border border-white/10 bg-slate-900/80 px-5 py-2 font-medium text-slate-200 transition hover:border-white/30 hover:text-white"
          >
            Read the rules
          </Link>
        </div>
      </div>
    </main>
  )
}
