import { getTopPlayers } from '@/lib/leaderboard'

export async function GET() {
  const players = getTopPlayers()

  return new Response(JSON.stringify({ players }), {
    headers: { 'content-type': 'application/json' }
  })
}
