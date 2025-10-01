import { NextResponse } from 'next/server'
import { fetchTopPlayers } from '@/lib/leaderboard'

export async function GET() {
  try {
    const players = await fetchTopPlayers(30)

    return NextResponse.json({ players })
  } catch (error) {
    console.error('Failed to fetch leaderboard top players', error)
    return NextResponse.json(
      { error: 'Unable to load leaderboard at this time.' },
      {
        status: 500
      }
    )
  }
}
