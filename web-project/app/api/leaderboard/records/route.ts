import { getRecordHolders } from '@/lib/leaderboard'

export async function GET() {
  const { kos, wos } = getRecordHolders()

  return new Response(JSON.stringify({ kos, wos }), {
    headers: { 'content-type': 'application/json' }
  })
}
