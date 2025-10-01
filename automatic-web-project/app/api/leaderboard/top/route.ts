import { NextRequest, NextResponse } from 'next/server'

import { prisma } from '@/lib/prisma'

const DEFAULT_LIMIT = 50
const MAX_LIMIT = 200

function parseLimit(request: NextRequest): number {
  const value = request.nextUrl.searchParams.get('limit')
  if (!value) {
    return DEFAULT_LIMIT
  }
  const parsed = Number.parseInt(value, 10)
  if (Number.isNaN(parsed) || parsed <= 0) {
    return DEFAULT_LIMIT
  }
  return Math.min(Math.max(parsed, 1), MAX_LIMIT)
}

export async function GET(request: NextRequest) {
  const limit = parseLimit(request)

  const players = await prisma.player.findMany({
    take: limit,
    orderBy: [
      { points: 'desc' },
      { kos: 'desc' },
      { wos: 'asc' },
    ],
    select: {
      userId: true,
      username: true,
      rank: true,
      points: true,
      kos: true,
      wos: true,
      lastSyncedAt: true,
    },
  })

  return NextResponse.json({
    players: players.map((player) => ({
      userId: Number(player.userId),
      username: player.username,
      rank: player.rank,
      points: player.points,
      kos: player.kos,
      wos: player.wos,
      lastSyncedAt: player.lastSyncedAt.toISOString(),
    })),
  })
}
