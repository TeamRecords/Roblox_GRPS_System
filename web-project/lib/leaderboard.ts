import { prisma } from './db'

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
    const players = await prisma.player.findMany({
      orderBy: [
        { points: 'desc' },
        { kos: 'desc' }
      ],
      take: limit
    })

    return players.map((player) => ({
      userId: player.userId,
      username: player.username,
      rank: player.rank ?? null,
      points: player.points ?? null,
      kos: player.kos ?? null,
      wos: player.wos ?? null,
      updatedAt: player.updatedAt
    }))
  } catch (error) {
    console.error('Falling back to static leaderboard payload', error)
    return FALLBACK_PLAYERS.slice(0, limit)
  }
}

export async function fetchRecordHolders(limit = 5): Promise<LeaderboardRecords> {
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
      kos: topKos.map((player) => ({
        userId: player.userId,
        username: player.username,
        kos: player.kos ?? null
      })),
      wos: topWos.map((player) => ({
        userId: player.userId,
        username: player.username,
        wos: player.wos ?? null
      }))
    }
  } catch (error) {
    console.error('Falling back to static record payload', error)
    return FALLBACK_RECORDS
  }
}
