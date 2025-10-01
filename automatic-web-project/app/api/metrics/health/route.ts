import { addHours } from 'date-fns'
import { NextResponse } from 'next/server'

import { prisma } from '@/lib/prisma'

export const dynamic = 'force-dynamic'

export async function GET() {
  const now = new Date()
  const updatedAfter = addHours(now, -1)

  const [totalPlayers, updatedLastHour] = await Promise.all([
    prisma.player.count(),
    prisma.player.count({
      where: {
        updatedAt: {
          gte: updatedAfter,
        },
      },
    }),
  ])

  return NextResponse.json({
    timestamp: now.toISOString(),
    totalPlayers,
    updatedLastHour,
  })
}
