import Link from 'next/link'

export default function NotFound() {
  return (
    <main className="flex min-h-[70vh] items-center justify-center px-6 py-24">
      <div className="max-w-xl text-center">
        <div className="mx-auto flex h-24 w-24 items-center justify-center rounded-3xl bg-gradient-to-br from-yellow-500 to-amber-600 text-3xl font-bold text-black shadow-[0_20px_45px_-15px_rgba(250,204,21,0.8)]">
          404
        </div>
        <h1 className="mt-8 text-4xl font-semibold text-white">Signal lost in the empire</h1>
        <p className="mt-4 text-sm text-zinc-300">
          The page you&apos;re looking for doesn&apos;t exist or has been moved. Explore the latest leaderboard standings or
          head to our legal center for more information.
        </p>
        <div className="mt-8 flex flex-wrap justify-center gap-4 text-sm">
          <Link
            href="/"
            className="rounded-full border border-amber-500/30 bg-amber-500/10 px-5 py-2 font-medium text-amber-200 shadow-lg transition hover:border-amber-400/40 hover:bg-amber-500/20"
          >
            Back to leaderboard
          </Link>
          <Link
            href="/legal/leaderstats-rules"
            className="rounded-full border border-amber-500/20 bg-black/70 px-5 py-2 font-medium text-zinc-200 transition hover:border-amber-400/40 hover:text-amber-200"
          >
            Read the rules
          </Link>
        </div>
      </div>
    </main>
  )
}
