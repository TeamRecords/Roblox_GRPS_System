import type { Metadata } from 'next'
import Link from 'next/link'

export const metadata: Metadata = {
  title: 'Legal | RLE Leaderboard',
  description: 'Read the legal policies that govern participation in the GRPS leaderboard.'
}

export default function LegalLayout({ children }: { children: React.ReactNode }) {
  return (
    <div className="px-6 pb-20 pt-16">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-10 lg:flex-row lg:gap-16">
        <aside className="panel p-8 lg:w-72">
          <h1 className="text-3xl font-semibold text-yellow-100" data-signal>
            Legal Center
          </h1>
          <p className="mt-4 text-sm leading-relaxed text-zinc-400">
            These terms, policies, and rules outline how the GRPS leaderboard operates. Review them carefully to remain in
            compliance with Roblox and Discord directives.
          </p>
          <nav className="mt-8 grid gap-3 text-sm uppercase tracking-[0.3em] text-zinc-500">
            <Link className="hover:text-yellow-200" href="/legal/terms-of-service">
              Terms of Service
            </Link>
            <Link className="hover:text-yellow-200" href="/legal/privacy-policy">
              Privacy Policy
            </Link>
            <Link className="hover:text-yellow-200" href="/legal/leaderstats-rules">
              Leaderboard Rules
            </Link>
          </nav>
        </aside>
        <div className="panel-emphasis flex-1 p-10">
          {children}
        </div>
      </div>
    </div>
  )
}
