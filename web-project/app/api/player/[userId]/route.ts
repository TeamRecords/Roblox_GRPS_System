import type { NextRequest } from 'next/server'
import { NextResponse } from 'next/server'
import { prisma } from '@/lib/db'

interface PlayerRouteContext {
  params: Promise<Record<string, string | string[] | undefined>>
}

export async function GET(_: NextRequest, { params }: PlayerRouteContext) {
  const resolvedParams = await params
  const rawUserId = resolvedParams.userId
  const userIdValue = Array.isArray(rawUserId) ? rawUserId[0] : rawUserId
  const userId = Number.parseInt(userIdValue ?? '', 10)

  if (!Number.isSafeInteger(userId)) {
    return NextResponse.json({ error: 'Invalid player id supplied.' }, { status: 400 })
  }

  try {
    const player = await prisma.player.findUnique({
      where: { userId }
    })

    if (!player) {
      return NextResponse.json({ error: 'Player not found.' }, { status: 404 })
    }

    return NextResponse.json({
      userId: player.userId,
      username: player.username,
      rank: player.rank ?? null,
      points: player.points ?? null,
      kos: player.kos ?? null,
      wos: player.wos ?? null,
      updatedAt: player.updatedAt,
      history: []
    })
  } catch (error) {
    console.error('Failed to query player', error)
    return NextResponse.json({ error: 'Unable to load player profile.' }, { status: 500 })
  }
}
