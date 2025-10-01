import {
  getRecordHolders,
  getTopPlayers,
  type LeaderboardPlayer,
  type LeaderboardRecords
} from '@/lib/leaderboard'

type LeaderboardResponse = {
  players: LeaderboardPlayer[]
}

async function fetchLeaderboard(): Promise<LeaderboardResponse> {
  const baseUrl = process.env.NEXT_PUBLIC_GRPS_API

  if (!baseUrl) {
    return { players: getTopPlayers() }
  }

  const response = await fetch(`${baseUrl.replace(/\/$/, '')}/leaderboard/top`, {
    cache: 'no-store'
  })

  if (!response.ok) {
    throw new Error('Failed to load leaderboard')
  }

  const payload = (await response.json()) as LeaderboardResponse

  return payload
}

async function fetchTopKOsWOs(): Promise<LeaderboardRecords> {
  const baseUrl = process.env.NEXT_PUBLIC_GRPS_API

  if (!baseUrl) {
    return getRecordHolders()
  }

  const response = await fetch(`${baseUrl.replace(/\/$/, '')}/leaderboard/records`, {
    cache: 'no-store'
  })

  if (!response.ok) {
    throw new Error('Failed to load record holders')
  }

  const payload = (await response.json()) as LeaderboardRecords

  return payload
}

export default async function Home() {
  const data = await fetchLeaderboard()
  const records = await fetchTopKOsWOs()

  return (
    <main className="container mx-auto p-6 space-y-8">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold">RLE Global Leaderboard</h1>
        <p className="text-slate-400">Top players across RLE.</p>
      </header>

      <section>
        <h2 className="text-xl font-semibold mb-3">Top 25 Players</h2>

        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
          {data.players?.map((player, index) => (
            <div key={player.userId} className="rounded-xl border border-slate-800 p-4">
              <div className="text-slate-400">#{index + 1}</div>
              <div className="text-lg font-semibold">{player.username}</div>
              <div className="text-sm text-slate-400">Rank: {player.rank} · Points: {player.points}</div>
              <div className="text-sm text-slate-500">KOs: {player.kos} · WOs: {player.wos}</div>
            </div>
          ))}
        </div>
      </section>

      <section className="grid md:grid-cols-2 gap-6">
        <div>
          <h2 className="text-xl font-semibold mb-3">Top KOs (All-time)</h2>
          <ol className="space-y-2 list-decimal list-inside">
            {records.kos?.slice(0, 5).map((entry) => (
              <li key={entry.userId} className="text-slate-200">
                {entry.username} — {entry.kos}
              </li>
            ))}
          </ol>
        </div>

        <div>
          <h2 className="text-xl font-semibold mb-3">Top WOs (All-time)</h2>
          <ol className="space-y-2 list-decimal list-inside">
            {records.wos?.slice(0, 5).map((entry) => (
              <li key={entry.userId} className="text-slate-200">
                {entry.username} — {entry.wos}
              </li>
            ))}
          </ol>
        </div>
      </section>
    </main>
  )
}
