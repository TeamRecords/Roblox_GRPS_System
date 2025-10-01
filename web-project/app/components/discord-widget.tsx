import Link from 'next/link'

const DISCORD_WIDGET_URL = 'https://discord.com/api/guilds/1402976697044832276/widget.json'
const SKIP_WIDGET_FETCH =
  process.env.SKIP_EXTERNAL_FETCH === 'true' || process.env.CI === '1' || process.env.NEXT_RUNTIME === 'edge'

export type DiscordWidget = {
  id: string
  name: string
  instant_invite?: string
  presence_count?: number
  members?: Array<{ id: string; username: string; status: string }>
}

async function loadDiscordWidget(): Promise<DiscordWidget | null> {
  if (SKIP_WIDGET_FETCH) {
    return null
  }

  try {
    const response = await fetch(DISCORD_WIDGET_URL, {
      next: { revalidate: 300 },
      headers: {
        accept: 'application/json'
      }
    })

    if (!response.ok) {
      return null
    }

    const payload = (await response.json()) as DiscordWidget

    return payload
  } catch (error) {
    console.error('Failed to load Discord widget', error)
    return null
  }
}

export async function DiscordWidgetPanel() {
  const widget = await loadDiscordWidget()
  const invite = widget?.instant_invite ?? 'https://discord.gg/cXKEdAKdWv'
  const onlineAgents = widget?.presence_count ?? 0

  return (
    <div className="space-y-4">
      <header className="space-y-2">
        <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">Discord Relay</p>
        <p className="text-2xl font-semibold text-yellow-200" data-signal>
          {widget?.name ?? 'GRPS Command'}
        </p>
      </header>
      <p className="text-sm leading-relaxed text-zinc-400">
        Live feed direct from the Roblox GRPS Discord stronghold. Maintain encrypted chatter and align raids with
        imperial oversight.
      </p>
      <div className="flex flex-wrap items-end justify-between gap-3">
        <div>
          <p className="text-4xl font-semibold text-yellow-300" data-signal>
            {onlineAgents.toLocaleString()}
          </p>
          <p className="text-xs uppercase tracking-[0.3em] text-zinc-500">Operatives online</p>
        </div>
        <Link
          href={invite}
          target="_blank"
          rel="noreferrer noopener"
          className="inline-flex items-center gap-2 rounded-full bg-yellow-500/15 px-4 py-2 text-xs font-medium uppercase tracking-[0.25em] text-yellow-200 transition hover:bg-yellow-500/25"
        >
          Join Relay
        </Link>
      </div>
      <p className="text-xs text-zinc-600">
        Server ID: 1402976697044832276 · Webhook feed polled securely every five minutes.
      </p>
      {!widget && (
        <p className="text-xs text-red-300">Unable to reach Discord widget. Access remains available via the invite link.</p>
      )}
    </div>
  )
}
