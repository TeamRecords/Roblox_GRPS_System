import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Legal | RLE Leaderboard',
  description: 'Read the legal policies that govern participation in the GRPS leaderboard.'
}

export default function LegalLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="border-y border-amber-500/10 bg-black/80">
      <div className="mx-auto flex w-full max-w-5xl flex-col gap-8 px-6 py-16 lg:flex-row lg:gap-12">
        <aside className="lg:w-64">
          <h1 className="text-3xl font-semibold text-white">Legal Command</h1>
          <p className="mt-3 text-sm text-zinc-400">
            These decrees govern the GRPS leaderboard. Study them to remain aligned with Roblox, Discord, and imperial protocol.
          </p>
          <nav className="mt-8 space-y-3 text-sm text-amber-200">
            <a className="block rounded-lg border border-amber-500/20 bg-black/60 px-4 py-3 transition hover:border-amber-400/40 hover:bg-amber-500/10 hover:text-amber-200" href="/legal/terms-of-service">
              Terms of Service
            </a>
            <a className="block rounded-lg border border-amber-500/20 bg-black/60 px-4 py-3 transition hover:border-amber-400/40 hover:bg-amber-500/10 hover:text-amber-200" href="/legal/privacy-policy">
              Privacy Policy
            </a>
            <a className="block rounded-lg border border-amber-500/20 bg-black/60 px-4 py-3 transition hover:border-amber-400/40 hover:bg-amber-500/10 hover:text-amber-200" href="/legal/leaderstats-rules">
              Leaderboard Rules
            </a>
          </nav>
        </aside>
        <div className="flex-1 space-y-10 rounded-3xl border border-amber-500/20 bg-[#09090f]/80 p-8 shadow-lg backdrop-blur">
          {children}
        </div>
      </div>
    </div>
  )
}
