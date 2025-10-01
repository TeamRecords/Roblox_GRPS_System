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

async function fetchFromAutomation<T>(path: string): Promise<T> {
  const baseUrl = automationBaseUrl()
  if (!baseUrl) {
    throw new Error('Automation base URL not configured')
  }

  const response = await fetch(`${baseUrl}${path}`, {
    cache: 'no-store',
    headers: { 'accept': 'application/json' }
  })

  if (!response.ok) {
    throw new Error(`Automation request failed (${response.status})`)
  }

  return (await response.json()) as T
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

const FALLBACK_PLAYERS: LeaderboardPlayer[] = Array.from({ length: 30 }).map((_, index) => ({
  userId: 8000 + index,
  username: `Phantom${index + 1}`,
  rank: 'Classified Operative',
  points: 5000 - index * 120,
  kos: 900 - index * 9,
  wos: 210 + index * 4,
  updatedAt: null
}))

const FALLBACK_RECORDS: LeaderboardRecords = {
  kos: [
    { userId: 8101, username: 'Abyss', kos: 1245 },
    { userId: 8102, username: 'Spectre', kos: 1187 },
    { userId: 8103, username: 'Cipher', kos: 1112 },
    { userId: 8104, username: 'Harrier', kos: 1068 },
    { userId: 8105, username: 'Revenant', kos: 1001 }
  ],
  wos: [
    { userId: 8201, username: 'Viper', wos: 972 },
    { userId: 8202, username: 'Obsidian', wos: 945 },
    { userId: 8203, username: 'Nocturne', wos: 902 },
    { userId: 8204, username: 'Drakon', wos: 876 },
    { userId: 8205, username: 'Helix', wos: 860 }
  ]
}

export async function fetchTopPlayers(limit = 30): Promise<LeaderboardPlayer[]> {
  try {
    const params = new URLSearchParams({ limit: String(limit) })
    const payload = await fetchFromAutomation<LeaderboardTopResponse>(`/leaderboard/top?${params.toString()}`)

    return payload.players.map((player) => ({
      userId: player.userId,
      username: player.username,
      rank: player.rank ?? null,
      points: player.points ?? null,
      kos: player.kos ?? null,
      wos: player.wos ?? null,
      updatedAt: player.lastSyncedAt ? new Date(player.lastSyncedAt) : null
    }))
  } catch (error) {
    console.error('Falling back to Prisma leaderboard payload', error)
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
    console.error('Falling back to static leaderboard payload', error)
    return FALLBACK_PLAYERS.slice(0, limit)
  }
}

export async function fetchRecordHolders(limit = 5): Promise<LeaderboardRecords> {
  try {
    const params = new URLSearchParams({ limit: String(limit) })
    const payload = await fetchFromAutomation<LeaderboardRecordsResponse>(`/leaderboard/records?${params.toString()}`)

    return {
      kos: payload.kos.map((entry) => ({
        userId: entry.userId,
        username: entry.username,
        kos: entry.kos ?? null
      })),
      wos: payload.wos.map((entry) => ({
        userId: entry.userId,
        username: entry.username,
        wos: entry.wos ?? null
      }))
    }
  } catch (error) {
    console.error('Falling back to Prisma record payload', error)
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
    console.error('Falling back to static record payload', error)
    return FALLBACK_RECORDS
  }
}
