import type { Metadata } from 'next'

export const metadata: Metadata = {
  title: 'Legal | RLE Leaderboard',
  description: 'Read the legal policies that govern participation in the GRPS leaderboard.'
}

export default function LegalLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="border-y border-white/10 bg-slate-950/80">
      <div className="mx-auto flex w-full max-w-5xl flex-col gap-8 px-6 py-16 lg:flex-row lg:gap-12">
        <aside className="lg:w-64">
          <h1 className="text-3xl font-semibold">Legal Center</h1>
          <p className="mt-3 text-sm text-slate-400">
            These terms, policies, and rules outline how the GRPS leaderboard operates. Review them carefully to stay in
            compliance with Roblox and Discord requirements.
          </p>
          <nav className="mt-8 space-y-3 text-sm text-slate-300">
            <a className="block rounded-lg border border-transparent px-4 py-3 transition hover:border-white/20 hover:bg-white/5 hover:text-white" href="/legal/terms-of-service">
              Terms of Service
            </a>
            <a className="block rounded-lg border border-transparent px-4 py-3 transition hover:border-white/20 hover:bg-white/5 hover:text-white" href="/legal/privacy-policy">
              Privacy Policy
            </a>
            <a className="block rounded-lg border border-transparent px-4 py-3 transition hover:border-white/20 hover:bg-white/5 hover:text-white" href="/legal/leaderstats-rules">
              Leaderboard Rules
            </a>
          </nav>
        </aside>
        <div className="flex-1 space-y-10 rounded-3xl border border-white/10 bg-slate-900/60 p-8 shadow-lg backdrop-blur">
          {children}
        </div>
      </div>
    </div>
  )
}
