import { NextRequest, NextResponse } from 'next/server'

import { prisma } from '@/lib/prisma'

const DEFAULT_LIMIT = 5
const MAX_LIMIT = 20

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

  const [kosLeaders, wosLeaders] = await Promise.all([
    prisma.player.findMany({
      take: limit,
      orderBy: [{ kos: 'desc' }, { points: 'desc' }],
      select: { userId: true, username: true, kos: true },
    }),
    prisma.player.findMany({
      take: limit,
      orderBy: [{ wos: 'asc' }, { points: 'desc' }],
      select: { userId: true, username: true, wos: true },
    }),
  ])

  return NextResponse.json({
    kos: kosLeaders.map((player) => ({
      userId: Number(player.userId),
      username: player.username,
      kos: player.kos,
    })),
    wos: wosLeaders.map((player) => ({
      userId: Number(player.userId),
      username: player.username,
      wos: player.wos,
    })),
  })
}
