import { NextResponse } from 'next/server'

const DISCORD_WIDGET_URL = 'https://discord.com/api/guilds/1402976697044832276/widget.json'

export async function GET() {
  try {
    const response = await fetch(DISCORD_WIDGET_URL, {
      next: { revalidate: 300 },
      headers: {
        accept: 'application/json'
      }
    })

    if (!response.ok) {
      return NextResponse.json({ error: 'Widget unavailable' }, { status: response.status })
    }

    const data = await response.json()

    return NextResponse.json({
      id: data.id,
      name: data.name,
      presenceCount: data.presence_count ?? 0,
      instantInvite: data.instant_invite ?? 'https://discord.gg/cXKEdAKdWv'
    })
  } catch (error) {
    console.error('Failed to reach Discord widget', error)
    return NextResponse.json({ error: 'Unable to reach Discord widget.' }, { status: 503 })
  }
}
