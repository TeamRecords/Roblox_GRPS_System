import {
  getRecordHolders,
  getTopPlayers,
  type LeaderboardPlayer,
  type LeaderboardRecords
} from '@/lib/leaderboard'

const FALLBACK_LIMIT = 25

type LeaderboardResponse = {
  players: LeaderboardPlayer[]
}

async function fetchLeaderboard(): Promise<LeaderboardResponse> {
  const baseUrl = process.env.NEXT_PUBLIC_GRPS_API

  if (!baseUrl) {
    return { players: getTopPlayers().slice(0, FALLBACK_LIMIT) }
  }

  const response = await fetch(`${baseUrl.replace(/\/$/, '')}/leaderboard/top`, {
    cache: 'no-store'
  })

  if (!response.ok) {
    throw new Error('Failed to load leaderboard')
  }

  const payload = (await response.json()) as LeaderboardResponse

  return {
    players: payload.players.slice(0, FALLBACK_LIMIT)
  }
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
  const topThree = data.players.slice(0, 3)
  const others = data.players.slice(3)

  return (
    <div className="relative overflow-hidden">
      <section className="mx-auto w-full max-w-6xl px-6 pb-12 pt-14 md:pt-20">
        <div className="grid gap-12 md:grid-cols-[1.1fr_0.9fr] md:items-center">
          <div className="space-y-6">
            <span className="inline-flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-3 py-1 text-xs uppercase tracking-[0.2em] text-slate-300">
              Live Leaderboard
            </span>
            <h1 className="text-4xl font-semibold leading-tight md:text-5xl">
              Track the top Roblox GRPS contenders and celebrate every milestone.
            </h1>
            <p className="max-w-xl text-lg text-slate-300">
              Monitor player performance, discover record holders, and keep up with the competition. The leaderboard updates from our official GRPS data sources so you always know who&apos;s leading the charge.
            </p>
            <div className="flex flex-wrap gap-4 text-sm text-slate-300">
              <div className="rounded-full border border-white/10 bg-white/5 px-4 py-2 backdrop-blur">
                Secure &amp; real-time data
              </div>
              <div className="rounded-full border border-white/10 bg-white/5 px-4 py-2 backdrop-blur">
                Official Roblox leaderstats
              </div>
              <div className="rounded-full border border-white/10 bg-white/5 px-4 py-2 backdrop-blur">
                Curated records
              </div>
            </div>
          </div>

          <div className="grid gap-4">
            {topThree.map((player, index) => (
              <div
                key={player.userId}
                className="gradient-border relative overflow-hidden rounded-3xl bg-slate-900/60 p-6 shadow-2xl backdrop-blur card-sheen"
              >
                <div className="flex items-start justify-between">
                  <div className="space-y-2">
                    <p className="text-sm uppercase tracking-[0.4em] text-slate-400">Rank #{index + 1}</p>
                    <h2 className="text-2xl font-semibold">{player.username}</h2>
                    <p className="text-sm text-slate-300">
                      {player.rank} • {player.points.toLocaleString()} pts
                    </p>
                  </div>
                  <div className="flex h-14 w-14 items-center justify-center rounded-2xl bg-gradient-to-br from-blue-500 to-violet-500 text-xl font-semibold text-white shadow-lg">
                    {player.kos}
                  </div>
                </div>
                <div className="mt-6 grid grid-cols-2 gap-3 text-xs text-slate-300">
                  <div className="rounded-2xl bg-white/5 px-3 py-2 text-center">
                    <p className="text-[0.7rem] uppercase tracking-[0.35em] text-slate-400">KOs</p>
                    <p className="text-base font-semibold text-white">{player.kos.toLocaleString()}</p>
                  </div>
                  <div className="rounded-2xl bg-white/5 px-3 py-2 text-center">
                    <p className="text-[0.7rem] uppercase tracking-[0.35em] text-slate-400">WOs</p>
                    <p className="text-base font-semibold text-white">{player.wos.toLocaleString()}</p>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </section>

      <section className="border-t border-white/5 bg-slate-950/60">
        <div className="mx-auto w-full max-w-6xl space-y-8 px-6 py-12">
          <div className="flex flex-col items-start justify-between gap-4 md:flex-row md:items-center">
            <div>
              <h2 className="text-2xl font-semibold">Top 25 Players</h2>
              <p className="text-sm text-slate-400">Sorted by the highest performance points across the GRPS network.</p>
            </div>
            <div className="flex items-center gap-2 rounded-full border border-white/10 bg-white/5 px-4 py-2 text-xs uppercase tracking-[0.3em] text-slate-300">
              Updated automatically
            </div>
          </div>

          <div className="grid gap-3 md:grid-cols-2 xl:grid-cols-3">
            {others.map((player, index) => (
              <article
                key={player.userId}
                className="card-sheen gradient-border rounded-2xl p-5 transition-transform hover:-translate-y-1"
              >
                <div className="flex items-start justify-between">
                  <div>
                    <p className="text-xs uppercase tracking-[0.4em] text-slate-400">#{index + 4}</p>
                    <h3 className="mt-2 text-lg font-semibold text-white">{player.username}</h3>
                    <p className="text-sm text-slate-300">{player.rank}</p>
                  </div>
                  <div className="text-right text-sm text-slate-400">
                    <p>
                      <span className="text-white">{player.points.toLocaleString()}</span> pts
                    </p>
                    <p>KOs: {player.kos.toLocaleString()}</p>
                    <p>WOs: {player.wos.toLocaleString()}</p>
                  </div>
                </div>
              </article>
            ))}

            {others.length === 0 && (
              <p className="rounded-2xl border border-dashed border-white/10 bg-slate-900/40 p-6 text-center text-slate-300">
                Leaderboard data is currently unavailable. Please check back soon.
              </p>
            )}
          </div>
        </div>
      </section>

      <section className="border-t border-white/5 bg-slate-950/40">
        <div className="mx-auto grid w-full max-w-6xl gap-8 px-6 py-12 md:grid-cols-[1.2fr_0.8fr] md:items-start">
          <div className="space-y-6">
            <h2 className="text-2xl font-semibold">Record Spotlights</h2>
            <p className="text-sm text-slate-400">
              These players hold the all-time records for total knockouts (KOs) and wipeouts (WOs) in the GRPS leaderboard.
            </p>
            <div className="grid gap-4 md:grid-cols-2">
              <div className="card-sheen rounded-3xl p-6">
                <h3 className="text-sm uppercase tracking-[0.3em] text-slate-400">Top KOs</h3>
                <ol className="mt-4 space-y-3 text-sm text-slate-200">
                  {records.kos?.slice(0, 5).map((entry, index) => (
                    <li key={entry.userId} className="flex items-center justify-between">
                      <span>
                        <span className="mr-2 text-xs text-slate-400">#{index + 1}</span>
                        {entry.username}
                      </span>
                      <span className="font-semibold text-white">{entry.kos.toLocaleString()}</span>
                    </li>
                  ))}
                </ol>
              </div>

              <div className="card-sheen rounded-3xl p-6">
                <h3 className="text-sm uppercase tracking-[0.3em] text-slate-400">Top WOs</h3>
                <ol className="mt-4 space-y-3 text-sm text-slate-200">
                  {records.wos?.slice(0, 5).map((entry, index) => (
                    <li key={entry.userId} className="flex items-center justify-between">
                      <span>
                        <span className="mr-2 text-xs text-slate-400">#{index + 1}</span>
                        {entry.username}
                      </span>
                      <span className="font-semibold text-white">{entry.wos.toLocaleString()}</span>
                    </li>
                  ))}
                </ol>
              </div>
            </div>
          </div>

          <div className="card-sheen rounded-3xl p-6">
            <h3 className="text-sm uppercase tracking-[0.3em] text-slate-400">Compete with Confidence</h3>
            <p className="mt-4 text-sm text-slate-300">
              The GRPS leaderboard is monitored to ensure fair play across the Roblox experience. Points, KOs, and WOs are verified against our server-side logs and Roblox data policies. Join the competition, play with integrity, and secure your spot on the board.
            </p>
            <div className="mt-6 space-y-4 text-sm text-slate-300">
              <p>• Updated live from official Roblox leaderstats.</p>
              <p>• Anti-cheat systems monitor suspicious activity.</p>
              <p>• Report any leaderboard issues to the GRPS moderation team.</p>
            </div>
          </div>
        </div>
      </section>
    </div>
  )
}
