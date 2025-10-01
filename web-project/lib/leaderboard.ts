import { prisma } from './db'

type PrismaPlayer = Awaited<ReturnType<(typeof prisma)['player']['findMany']>>[number]

type LeaderboardTopResponse = {
  players: Array<{
    userId: number
    username: string
    rank?: string | null
    points?: number | null
    kos?: number | null
    wos?: number | null
    lastSyncedAt?: string | null
  }>
  lastSyncedAt?: string | null
}

type LeaderboardRecordsResponse = {
  kos: Array<{ userId: number; username: string; kos?: number | null }>
  wos: Array<{ userId: number; username: string; wos?: number | null }>
}

function toNumber(value: number | bigint | null | undefined): number | null {
  if (value === null || value === undefined) {
    return null
  }

  return Number(value)
}

function automationBaseUrl(): string | null {
  return process.env.NEXT_PUBLIC_AUTOMATION_BASE_URL ?? process.env.GRPS_AUTOMATION_BASE_URL ?? null
}

async function fetchAutomationPayload<T>(path: string): Promise<T | undefined> {
  const baseUrl = automationBaseUrl()
  if (!baseUrl) {
    return undefined
  }

  try {
    const response = await fetch(`${baseUrl}${path}`, {
      cache: 'no-store',
      headers: { accept: 'application/json' }
    })

    if (!response.ok) {
      throw new Error(`automation request failed (${response.status})`)
    }

    return (await response.json()) as T
  } catch (error) {
    console.error('Failed to fetch automation payload', { path, error })
    return undefined
  }
}

export type LeaderboardPlayer = {
  userId: number
  username: string
  rank: string | null
  points: number | null
  kos: number | null
  wos: number | null
  updatedAt?: Date | null
}

export type LeaderboardRecords = {
  kos: Array<{ userId: number; username: string; kos: number | null }>
  wos: Array<{ userId: number; username: string; wos: number | null }>
}

export async function fetchTopPlayers(limit = 30): Promise<LeaderboardPlayer[]> {
  const params = new URLSearchParams({ limit: String(limit) })
  const automationPayload = await fetchAutomationPayload<LeaderboardTopResponse>(
    `/leaderboard/top?${params.toString()}`
  )

  if (automationPayload) {
    return automationPayload.players.map((player) => ({
      userId: player.userId,
      username: player.username,
      rank: player.rank ?? null,
      points: player.points ?? null,
      kos: player.kos ?? null,
      wos: player.wos ?? null,
      updatedAt: player.lastSyncedAt ? new Date(player.lastSyncedAt) : null
    }))
  }

  try {
    const players = await prisma.player.findMany({
      orderBy: [
        { points: 'desc' },
        { kos: 'desc' }
      ],
      take: limit
    })

    return players.map((player: PrismaPlayer) => ({
      userId: Number(player.userId),
      username: player.username,
      rank: player.rank ?? null,
      points: toNumber(player.points),
      kos: toNumber(player.kos),
      wos: toNumber(player.wos),
      updatedAt: player.updatedAt
    }))
  } catch (error) {
    console.error('Failed to fetch leaderboard payload from Prisma', error)
    return []
  }
}

export async function fetchRecordHolders(limit = 5): Promise<LeaderboardRecords> {
  const params = new URLSearchParams({ limit: String(limit) })
  const automationPayload = await fetchAutomationPayload<LeaderboardRecordsResponse>(
    `/leaderboard/records?${params.toString()}`
  )

  if (automationPayload) {
    return {
      kos: automationPayload.kos.map((entry) => ({
        userId: entry.userId,
        username: entry.username,
        kos: entry.kos ?? null
      })),
      wos: automationPayload.wos.map((entry) => ({
        userId: entry.userId,
        username: entry.username,
        wos: entry.wos ?? null
      }))
    }
  }

  try {
    const [topKos, topWos] = await Promise.all([
      prisma.player.findMany({
        orderBy: { kos: 'desc' },
        take: limit
      }),
      prisma.player.findMany({
        orderBy: { wos: 'desc' },
        take: limit
      })
    ])

    return {
      kos: topKos.map((player: PrismaPlayer) => ({
        userId: Number(player.userId),
        username: player.username,
        kos: toNumber(player.kos)
      })),
      wos: topWos.map((player: PrismaPlayer) => ({
        userId: Number(player.userId),
        username: player.username,
        wos: toNumber(player.wos)
      }))
    }
  } catch (error) {
    console.error('Failed to fetch leaderboard records from Prisma', error)
    return { kos: [], wos: [] }
  }
}
