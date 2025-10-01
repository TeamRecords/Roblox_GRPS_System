import { createHmac } from 'crypto'

import { NextRequest, NextResponse } from 'next/server'

import { prisma } from '@/lib/prisma'

const SIGNATURE_HEADER = 'x-grps-signature'
const signatureSecret = process.env.AUTOMATION_SIGNATURE_SECRET ?? process.env.GRPS_AUTOMATION_SIGNATURE_SECRET ?? ''

function normalisePayload(payload: unknown) {
  const activity = typeof (payload as { activity?: string })?.activity === 'string' ? (payload as { activity: string }).activity : 'leaderboard'
  const limitValue = Number.parseInt(String((payload as { limit?: number | string | null })?.limit ?? '0'), 10)
  const limit = Number.isNaN(limitValue) || limitValue <= 0 ? 100 : Math.min(Math.max(limitValue, 1), 500)
  const cursor = (payload as { cursor?: string | null })?.cursor ?? null
  return { activity, limit, cursor }
}

function verifySignature(signature: string | null, payload: object) {
  if (!signatureSecret) {
    return false
  }
  if (!signature) {
    return false
  }
  const canonicalPayload = JSON.stringify(payload)
  const digest = createHmac('sha256', signatureSecret).update(canonicalPayload).digest('hex')
  return digest === signature
}

export async function POST(request: NextRequest) {
  if (!signatureSecret) {
    return NextResponse.json({ error: 'Automation signature secret not configured' }, { status: 500 })
  }

  const incoming = await request.json().catch(() => null)
  const payload = normalisePayload(incoming)
  const signature = request.headers.get(SIGNATURE_HEADER)

  if (!verifySignature(signature, payload)) {
    return NextResponse.json({ error: 'Invalid signature' }, { status: 401 })
  }

  const recentPlayers = await prisma.player.findMany({
    take: payload.limit,
    orderBy: [{ updatedAt: 'desc' }],
    select: {
      userId: true,
      username: true,
      updatedAt: true,
    },
  })

  return NextResponse.json({
    activity: payload.activity,
    created: 0,
    updated: recentPlayers.length,
    players: recentPlayers.map((player) => ({
      userId: Number(player.userId),
      username: player.username,
      updatedAt: player.updatedAt.toISOString(),
    })),
    cursor: null,
  })
}
