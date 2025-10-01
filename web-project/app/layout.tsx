import type { Metadata } from 'next'
import { Inter } from 'next/font/google'
import './globals.css'

const inter = Inter({ subsets: ['latin'], variable: '--font-inter' })

export const metadata: Metadata = {
  title: 'RLE Leaderboard',
  description: 'Track the top RLE players and record holders in real time.'
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body
        className={`${inter.variable} font-sans bg-slate-950 text-slate-100 min-h-screen`}
      >
        <div className="fixed inset-0 -z-10 overflow-hidden">
          <div className="absolute inset-x-0 top-0 h-[600px] bg-gradient-to-b from-blue-500/20 via-purple-500/10 to-transparent blur-3xl" />
          <div className="absolute left-1/2 top-1/2 h-64 w-64 -translate-x-1/2 -translate-y-1/2 rounded-full bg-blue-500/20 blur-3xl" />
        </div>
        <div className="relative flex min-h-screen flex-col">
          <header className="border-b border-white/5 bg-slate-950/70 backdrop-blur">
            <div className="mx-auto flex w-full max-w-6xl items-center justify-between px-6 py-5">
              <div className="flex items-center gap-3">
                <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-blue-500 to-violet-500 font-semibold shadow-lg">
                  RLE
                </span>
                <div>
                  <p className="text-lg font-semibold tracking-tight">GRPS Leaderboard</p>
                  <p className="text-sm text-slate-400">Competitive Roblox leaderstats, refreshed live.</p>
                </div>
              </div>
              <nav className="hidden items-center gap-6 text-sm font-medium text-slate-300 md:flex">
                <a className="transition hover:text-white" href="/">Leaderboard</a>
                <a className="transition hover:text-white" href="/legal/terms-of-service">Terms</a>
                <a className="transition hover:text-white" href="/legal/privacy-policy">Privacy</a>
                <a className="transition hover:text-white" href="/legal/leaderstats-rules">Rules</a>
              </nav>
            </div>
            <nav className="mx-auto flex w-full max-w-6xl items-center gap-4 px-6 pb-4 text-sm text-slate-300 md:hidden">
              <a className="rounded-full border border-white/10 px-4 py-2 transition hover:border-white/30 hover:text-white" href="/">
                Leaderboard
              </a>
              <a className="rounded-full border border-white/10 px-4 py-2 transition hover:border-white/30 hover:text-white" href="/legal/terms-of-service">
                Terms
              </a>
              <a className="rounded-full border border-white/10 px-4 py-2 transition hover:border-white/30 hover:text-white" href="/legal/privacy-policy">
                Privacy
              </a>
              <a className="rounded-full border border-white/10 px-4 py-2 transition hover:border-white/30 hover:text-white" href="/legal/leaderstats-rules">
                Rules
              </a>
            </nav>
          </header>

          <main className="flex-1">
            {children}
          </main>

          <footer className="border-t border-white/5 bg-slate-950/80 py-8">
            <div className="mx-auto flex w-full max-w-6xl flex-col gap-4 px-6 text-sm text-slate-400 md:flex-row md:items-center md:justify-between">
              <p>© {new Date().getFullYear()} Roblox GRPS System. All rights reserved.</p>
              <div className="flex flex-wrap items-center gap-4">
                <a className="hover:text-white" href="/legal/terms-of-service">Terms of Service</a>
                <a className="hover:text-white" href="/legal/privacy-policy">Privacy Policy</a>
                <a className="hover:text-white" href="/legal/leaderstats-rules">Leaderboard Rules</a>
              </div>
            </div>
          </footer>
        </div>
      </body>
    </html>
  )
}
