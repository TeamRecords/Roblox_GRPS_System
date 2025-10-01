import { createHmac } from 'crypto'

import { NextRequest, NextResponse } from 'next/server'

import { prisma } from '@/lib/db'
import { fetchAutomationLeaderboard, triggerRobloxSync } from '@/lib/grpsBackendClient'

type SyncRequestBody = {
  limit?: number
  cursor?: string | null
  triggerRobloxSync?: boolean
  activity?: string
}

const SYNC_TOKEN_HEADER = 'x-grps-sync-token'
const SYNC_TOKEN = process.env.GRPS_SYNC_TOKEN ?? null
const SIGNATURE_SECRET = process.env.GRPS_AUTOMATION_SIGNATURE_SECRET ?? null
const DEFAULT_LIMIT = Math.min(
  Math.max(Number.parseInt(process.env.GRPS_SYNC_LIMIT ?? '100', 10) || 100, 1),
  500
)

function normaliseLimit(limit: unknown): number {
  const parsed = typeof limit === 'number' ? limit : Number.parseInt(String(limit ?? ''), 10)
  if (Number.isNaN(parsed) || parsed <= 0) {
    return DEFAULT_LIMIT
  }
  return Math.min(Math.max(parsed, 1), 500)
}

function authenticate(request: NextRequest): boolean {
  if (!SYNC_TOKEN) {
    return true
  }

  const headerToken = request.headers.get(SYNC_TOKEN_HEADER)
  if (headerToken && headerToken === SYNC_TOKEN) {
    return true
  }

  const authHeader = request.headers.get('authorization')
  if (authHeader && authHeader.startsWith('Bearer ')) {
    return authHeader.slice('Bearer '.length) === SYNC_TOKEN
  }

  return false
}

function computeSignature(payload: object): string | null {
  if (!SIGNATURE_SECRET) {
    return null
  }

  const serialized = JSON.stringify(payload)
  return createHmac('sha256', SIGNATURE_SECRET).update(serialized).digest('hex')
}

export async function POST(request: NextRequest) {
  if (!authenticate(request)) {
    return NextResponse.json({ error: 'Unauthorized' }, { status: 401 })
  }

  const body = (await request.json().catch(() => null)) as SyncRequestBody | null
  const limit = normaliseLimit(body?.limit ?? DEFAULT_LIMIT)
  const cursor = body?.cursor ?? null
  const activity = body?.activity ?? 'leaderboard'

  const syncPayload = { activity, limit, cursor }

  let automationResponse: unknown = null
  const shouldTriggerAutomation = body?.triggerRobloxSync ?? Boolean(SIGNATURE_SECRET)

  if (shouldTriggerAutomation && SIGNATURE_SECRET) {
    const signature = computeSignature(syncPayload)
    if (!signature) {
      return NextResponse.json({ error: 'Missing automation signature secret' }, { status: 500 })
    }

    try {
      automationResponse = await triggerRobloxSync(signature, syncPayload)
    } catch (error) {
      return NextResponse.json(
        { error: 'Failed to trigger automation sync', details: String(error) },
        { status: 502 }
      )
    }
  }

  let players: Awaited<ReturnType<typeof fetchAutomationLeaderboard>> = []
  try {
    players = await fetchAutomationLeaderboard(limit)
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to load automation leaderboard', details: String(error) },
      { status: 502 }
    )
  }

  if (players.length === 0) {
    return NextResponse.json({ playersProcessed: 0, created: 0, updated: 0, automationResponse })
  }

  const userIds = players
    .map((player) => {
      try {
        return BigInt(player.userId)
      } catch {
        return null
      }
    })
    .filter((value): value is bigint => value !== null)

  const existing = await prisma.player.findMany({
    where: { userId: { in: userIds } },
    select: { userId: true },
  })
  const existingSet = new Set(existing.map((record) => record.userId.toString()))

  let created = 0
  let updated = 0

  const operations: Array<ReturnType<typeof prisma.player.upsert>> = []

  for (const player of players) {
    let userId: bigint
    try {
      userId = BigInt(player.userId)
    } catch {
      continue
    }
    const lastSyncedAt = player.lastSyncedAt ? new Date(player.lastSyncedAt) : new Date()
    const record = {
      username: player.username,
      displayName: player.username,
      rank: player.rank ?? 'Unassigned Operative',
      points: player.points ?? 0,
      kos: player.kos ?? 0,
      wos: player.wos ?? 0,
      lastSyncedAt,
    }

    const exists = existingSet.has(userId.toString())
    if (exists) {
      updated += 1
    } else {
      created += 1
    }

    operations.push(
      prisma.player.upsert({
        where: { userId },
        update: {
          username: record.username,
          displayName: record.displayName,
          rank: record.rank,
          points: record.points,
          kos: record.kos,
          wos: record.wos,
          lastSyncedAt: record.lastSyncedAt,
        },
        create: {
          userId,
          username: record.username,
          displayName: record.displayName,
          rank: record.rank,
          previousRank: null,
          nextRank: null,
          points: record.points,
          kos: record.kos,
          wos: record.wos,
          warnings: 0,
          recommendations: 0,
          privileged: false,
          punishmentStatus: null,
          punishmentExpiresAt: null,
          metadata: {},
          lastSyncedAt: record.lastSyncedAt,
        },
      })
    )
  }

  try {
    await prisma.$transaction(operations)
  } catch (error) {
    return NextResponse.json(
      { error: 'Failed to persist leaderboard records', details: String(error) },
      { status: 500 }
    )
  }

  return NextResponse.json({
    playersProcessed: players.length,
    created,
    updated,
    automationResponse,
  })
}

export function GET() {
  return NextResponse.json({ error: 'Method Not Allowed' }, { status: 405 })
}

