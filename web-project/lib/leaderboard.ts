export type LeaderboardPlayer = {
  userId: number
  username: string
  rank: string
  points: number
  kos: number
  wos: number
}

export type LeaderboardRecords = {
  kos: Array<{ userId: number; username: string; kos: number }>
  wos: Array<{ userId: number; username: string; wos: number }>
}

export function getTopPlayers(): LeaderboardPlayer[] {
  return Array.from({ length: 25 }).map((_, index) => ({
    userId: 1000 + index,
    username: `Player${index + 1}`,
    rank: 'Volt Specialist II',
    points: 5000 - index * 100,
    kos: 1000 - index * 10,
    wos: 200 + index * 5
  }))
}

export function getRecordHolders(): LeaderboardRecords {
  return {
    kos: [
      { userId: 1, username: 'Alpha', kos: 1245 },
      { userId: 2, username: 'Bravo', kos: 1190 },
      { userId: 3, username: 'Charlie', kos: 1104 },
      { userId: 4, username: 'Delta', kos: 1060 },
      { userId: 5, username: 'Echo', kos: 1002 }
    ],
    wos: [
      { userId: 6, username: 'Orion', wos: 980 },
      { userId: 7, username: 'Nova', wos: 940 },
      { userId: 8, username: 'Vega', wos: 900 },
      { userId: 9, username: 'Rhea', wos: 870 },
      { userId: 10, username: 'Zeph', wos: 850 }
    ]
  }
}
