import type { NextRequest } from 'next/server'

type PlayerRouteContext = {
  params: Promise<Record<string, string | string[] | undefined>>
}

export async function GET(_: NextRequest, { params }: PlayerRouteContext) {
  const resolvedParams = await params
  const rawUserId = resolvedParams.userId
  const userId = Array.isArray(rawUserId)
    ? rawUserId[0] ?? ''
    : rawUserId ?? ''

  const data = {
    userId,
    username: `User${userId}`,
    rank: 'Thunder Sergeant II',
    points: 3450,
    kos: 420,
    wos: 220,
    history: [
      { date: '2025-09-01', change: +25, reason: 'Operation' },
      { date: '2025-09-02', change: +15, reason: 'Training' },
      { date: '2025-09-05', change: -2, reason: 'WO' }
    ]
  }

  return new Response(JSON.stringify(data), {
    headers: { 'content-type': 'application/json' }
  })
}
