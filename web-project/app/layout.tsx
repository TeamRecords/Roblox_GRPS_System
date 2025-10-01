import type { Metadata, Viewport } from 'next'
import { Inter, Orbitron } from 'next/font/google'
import Link from 'next/link'
import './globals.css'
import { DiscordWidgetPanel } from './components/discord-widget'

const inter = Inter({ subsets: ['latin'], variable: '--font-inter' })
const orbitron = Orbitron({ subsets: ['latin'], variable: '--font-orbitron' })

export const metadata: Metadata = {
  title: 'Roblox Imperial Command | GRPS Leaderboard',
  description:
    'Monitor Roblox GRPS leaderstats, command your roster, and relay intel across the imperial network in real time.',
  metadataBase: new URL('https://grps-imperial.example.com'),
  openGraph: {
    title: 'Roblox Imperial Command',
    description: 'Futuristic Roblox empire leaderboard and command dashboard.',
    url: 'https://grps-imperial.example.com',
    siteName: 'GRPS Imperial Command',
    type: 'website'
  },
  twitter: {
    card: 'summary_large_image',
    title: 'GRPS Imperial Command',
    description: 'Darker, secure Roblox leaderboard with live imperial intel.'
  }
}

export const viewport: Viewport = {
  themeColor: '#0c0c10',
  width: 'device-width',
  initialScale: 1
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en" className="bg-[#020204]">
      <body
        className={`${inter.variable} ${orbitron.variable} font-sans bg-[#020204] text-zinc-100 min-h-screen`}
      >
        <div className="relative flex min-h-screen flex-col">
          <main className="flex-1">{children}</main>
          <SiteFooter />
        </div>
      </body>
    </html>
  )
}

async function SiteFooter() {
  return (
    <footer className="px-6 pb-16 pt-12">
      <div className="mx-auto flex w-full max-w-6xl flex-col gap-10 lg:flex-row lg:items-start lg:justify-between">
        <div className="space-y-4 lg:max-w-sm">
          <span className="tag" data-signal>
            Imperial signal
          </span>
          <p className="text-3xl font-semibold text-yellow-200" data-signal>
            GRPS Command Nexus
          </p>
          <p className="text-sm leading-relaxed text-zinc-400">
            Surveillance-grade analytics for the Roblox Grand Power Syndicate. Stay encrypted, stay ruthless, and deploy via
            the official Discord relay.
          </p>
          <Link
            href="https://discord.gg/cXKEdAKdWv"
            target="_blank"
            rel="noreferrer noopener"
            className="inline-flex items-center gap-3 rounded-full bg-yellow-500/20 px-5 py-2 text-sm font-medium text-yellow-200 transition hover:bg-yellow-500/30"
          >
            Enter command channel
          </Link>
        </div>
        <nav className="grid gap-3 text-sm uppercase tracking-[0.3em] text-zinc-500">
          <Link className="hover:text-yellow-200" href="/">
            Command Deck
          </Link>
          <Link className="hover:text-yellow-200" href="/legal/terms-of-service">
            Terms of Service
          </Link>
          <Link className="hover:text-yellow-200" href="/legal/privacy-policy">
            Privacy Policy
          </Link>
          <Link className="hover:text-yellow-200" href="/legal/leaderstats-rules">
            Leaderstats Rules
          </Link>
          <Link className="hover:text-yellow-200" href="/errors/overload">
            System Overload
          </Link>
          <Link className="hover:text-yellow-200" href="/errors/lockdown">
            Security Lockdown
          </Link>
        </nav>
        <div className="panel-muted w-full max-w-md p-6">
          <DiscordWidgetPanel />
        </div>
      </div>
      <p className="mt-12 text-xs uppercase tracking-[0.35em] text-zinc-600">
        © {new Date().getFullYear()} Roblox GRPS System — Fortress-grade telemetry.
      </p>
    </footer>
  )
}
