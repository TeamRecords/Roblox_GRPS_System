import { fetchRecordHolders, fetchTopPlayers, type LeaderboardPlayer } from '@/lib/leaderboard'

export const dynamic = 'force-dynamic'
export const revalidate = 0

function formatNumber(value: number | null | undefined) {
  if (value === null || value === undefined) {
    return '—'
  }

  return value.toLocaleString()
}

function formatRank(player: LeaderboardPlayer) {
  return player.rank && player.rank.trim().length > 0 ? player.rank : 'Unassigned Operative'
}

function formatTimestamp(player: LeaderboardPlayer | undefined) {
  if (!player?.updatedAt) {
    return 'Awaiting sync'
  }

  return new Intl.DateTimeFormat('en', {
    hour: '2-digit',
    minute: '2-digit',
    month: 'short',
    day: '2-digit'
  }).format(new Date(player.updatedAt))
}

export default async function Home() {
  const [players, records] = await Promise.all([fetchTopPlayers(30), fetchRecordHolders(5)])

  const commandLeads = players.slice(0, 3)
  const extendedRoster = players.slice(3)
  const latestUpdate = formatTimestamp(players[0])
  const topKosValue = records.kos[0]?.kos ?? null
  const topWosValue = records.wos[0]?.wos ?? null
  const hasLeaderboardData = players.length > 0
  const hasRecordData = records.kos.length > 0 || records.wos.length > 0

  return (
    <div className="relative">
      <div className="mx-auto w-full max-w-6xl px-6 pb-24 pt-16 sm:pt-20">
        <section className="panel-emphasis overflow-hidden p-8 sm:p-12">
          <div className="flex flex-col gap-12 lg:flex-row lg:items-end lg:justify-between">
            <div className="space-y-6 lg:max-w-2xl">
              <span className="tag" data-signal>
                Imperial Broadcast
              </span>
              <h1 className="text-4xl font-semibold leading-tight text-yellow-100 sm:text-5xl" data-signal>
                Command the Roblox GRPS empire with ruthless precision.
              </h1>
              <p className="text-base leading-relaxed text-zinc-400">
                The command deck synchronises every knockout, wipeout, and promotion directly from the Postgres Neon vault.
                Analyse operatives, adjust raids, and broadcast orders without exposing sensitive intel.
              </p>
              <div className="stat-grid">
                <div className="panel-muted p-6">
                  <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">Tracked operatives</p>
                  <p className="mt-3 text-3xl font-semibold text-yellow-200" data-signal>
                    {players.length.toLocaleString()}
                  </p>
                  <p className="text-xs text-zinc-500">Live feed with null-safe leaderstats.</p>
                </div>
                <div className="panel-muted p-6">
                  <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">KO dossiers</p>
                  <p className="mt-3 text-3xl font-semibold text-yellow-200" data-signal>
                    {formatNumber(topKosValue)}
                  </p>
                  <p className="text-xs text-zinc-500">Highest confirmed eliminations.</p>
                </div>
                <div className="panel-muted p-6">
                  <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">WO dossiers</p>
                  <p className="mt-3 text-3xl font-semibold text-yellow-200" data-signal>
                    {formatNumber(topWosValue)}
                  </p>
                  <p className="text-xs text-zinc-500">Highest recorded wipeouts.</p>
                  <div className="mt-6 border-t border-zinc-800/60 pt-4 text-xs text-zinc-500">
                    <p className="uppercase tracking-[0.35em]">Last sync</p>
                    <p className="mt-1 text-base font-semibold text-yellow-200" data-signal>
                      {latestUpdate}
                    </p>
                    <p className="mt-1 text-[0.7rem] leading-relaxed text-zinc-500">
                      Pulled over secure API endpoints.
                    </p>
                  </div>
                </div>
              </div>
              {!hasLeaderboardData && (
                <div className="panel-muted border border-dashed border-yellow-500/40 p-6 text-sm text-zinc-400">
                  Nothing here yet. The automation service will publish the first operatives as soon as a Roblox snapshot is
                  ingested.
                </div>
              )}
              {hasLeaderboardData && !hasRecordData && (
                <div className="panel-muted border border-dashed border-yellow-500/40 p-6 text-sm text-zinc-400">
                  Player telemetry is live, but no record eliminations have been reported yet. Keep an eye on the Neon feed.
                </div>
              )}
            </div>
            <aside className="panel p-8 lg:w-80">
              <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">Security briefing</p>
              <ul className="mt-4 space-y-4 text-sm text-zinc-300">
                <li>
                  All API traffic is validated and sanitised. Null fields are tolerated to prevent sync failure.
                </li>
                <li>
                  Prisma routes rely on encrypted Neon Postgres connections with separate read endpoints.
                </li>
                <li>
                  Discord webhooks remain isolated through server-side polling of the official widget feed.
                </li>
              </ul>
            </aside>
          </div>
        </section>

        <section className="mt-16 space-y-8">
          <header className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">Chain of command</p>
              <h2 className="text-3xl font-semibold text-yellow-100" data-signal>
                Imperial champions
              </h2>
            </div>
            <p className="text-sm text-zinc-500">
              Top-three operatives currently steering the Roblox empire.
            </p>
          </header>
          <div className="grid gap-6 lg:grid-cols-3">
            {commandLeads.map((player, index) => (
              <article key={player.userId} className="panel p-8">
                <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">#{index + 1} Command Seat</p>
                <h3 className="mt-4 text-2xl font-semibold text-yellow-100" data-signal>
                  {player.username}
                </h3>
                <p className="mt-2 text-sm text-zinc-500">{formatRank(player)}</p>
                <dl className="mt-8 grid gap-4 text-sm text-yellow-100">
                  <div>
                    <dt className="text-xs uppercase tracking-[0.35em] text-zinc-500">Command score</dt>
                    <dd className="mt-1 text-xl font-semibold" data-signal>
                      {formatNumber(player.points)}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-xs uppercase tracking-[0.35em] text-zinc-500">Knockouts</dt>
                    <dd className="mt-1 text-xl font-semibold" data-signal>
                      {formatNumber(player.kos)}
                    </dd>
                  </div>
                  <div>
                    <dt className="text-xs uppercase tracking-[0.35em] text-zinc-500">Wipeouts</dt>
                    <dd className="mt-1 text-xl font-semibold" data-signal>
                      {formatNumber(player.wos)}
                    </dd>
                  </div>
                </dl>
              </article>
            ))}
            {commandLeads.length === 0 && (
              <p className="panel p-8 text-sm text-zinc-400">No champions reported yet. Synchronisation pending.</p>
            )}
          </div>
        </section>

        <section className="mt-16 space-y-6">
          <header className="flex flex-col gap-2 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">Extended roster</p>
              <h2 className="text-3xl font-semibold text-yellow-100" data-signal>
                Active operatives
              </h2>
            </div>
            <p className="text-sm text-zinc-500">Sorted by command score, resilient to missing stats.</p>
          </header>
          <div className="grid gap-4 md:grid-cols-2 xl:grid-cols-3">
            {extendedRoster.map((player, index) => (
              <article key={player.userId} className="panel-muted p-6">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">#{index + 4}</p>
                    <h3 className="mt-3 text-xl font-semibold text-yellow-100" data-signal>
                      {player.username}
                    </h3>
                    <p className="text-sm text-zinc-500">{formatRank(player)}</p>
                  </div>
                  <dl className="text-right text-xs text-zinc-500">
                    <div>
                      <dt>Score</dt>
                      <dd className="text-lg font-semibold text-yellow-200" data-signal>
                        {formatNumber(player.points)}
                      </dd>
                    </div>
                    <div className="mt-2">
                      <dt>KOs</dt>
                      <dd>{formatNumber(player.kos)}</dd>
                    </div>
                    <div className="mt-2">
                      <dt>WOs</dt>
                      <dd>{formatNumber(player.wos)}</dd>
                    </div>
                  </dl>
                </div>
              </article>
            ))}
            {extendedRoster.length === 0 && (
              <p className="panel-muted p-6 text-sm text-zinc-400">
                No additional operatives detected. Awaiting secure data ingestion.
              </p>
            )}
          </div>
        </section>

        <section className="mt-20 grid gap-8 lg:grid-cols-[1.1fr_0.9fr]">
          <div className="panel p-8">
            <header>
              <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">Record dossiers</p>
              <h2 className="mt-2 text-3xl font-semibold text-yellow-100" data-signal>
                Hall of eliminations
              </h2>
              <p className="mt-2 text-sm text-zinc-500">
                Highest recorded KOs and WOs maintained through Postgres snapshots.
              </p>
            </header>
            <div className="mt-10 grid gap-6 md:grid-cols-2">
              <div className="panel-muted p-6">
                <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">Top knockouts</p>
                <ol className="mt-4 space-y-3 text-sm text-yellow-100">
                  {records.kos.map((entry, index) => (
                    <li key={entry.userId} className="flex items-center justify-between gap-4">
                      <span>
                        <span className="mr-2 text-xs text-zinc-500">#{index + 1}</span>
                        {entry.username}
                      </span>
                      <span className="font-semibold text-yellow-200" data-signal>
                        {formatNumber(entry.kos)}
                      </span>
                    </li>
                  ))}
                  {records.kos.length === 0 && (
                    <li className="text-xs text-zinc-500">No KO records available.</li>
                  )}
                </ol>
              </div>
              <div className="panel-muted p-6">
                <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">Top wipeouts</p>
                <ol className="mt-4 space-y-3 text-sm text-yellow-100">
                  {records.wos.map((entry, index) => (
                    <li key={entry.userId} className="flex items-center justify-between gap-4">
                      <span>
                        <span className="mr-2 text-xs text-zinc-500">#{index + 1}</span>
                        {entry.username}
                      </span>
                      <span className="font-semibold text-yellow-200" data-signal>
                        {formatNumber(entry.wos)}
                      </span>
                    </li>
                  ))}
                  {records.wos.length === 0 && (
                    <li className="text-xs text-zinc-500">No WO records available.</li>
                  )}
                </ol>
              </div>
            </div>
          </div>

          <aside className="panel-emphasis p-8">
            <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">Operational doctrine</p>
            <ul className="mt-6 space-y-4 text-sm text-zinc-300">
              <li>
                Maintain Roblox compliance: exploits trigger automatic suppression and API quarantines.
              </li>
              <li>
                Submit anomalies through Discord webhooks — transmissions are stored securely inside Postgres snapshots.
              </li>
              <li>
                All stats hydrate via server actions. Client requests are rate-limited and sanitised.
              </li>
            </ul>
            <div className="mt-10 space-y-4">
              <p className="text-xs uppercase tracking-[0.35em] text-zinc-500">Need a tactical brief?</p>
              <p className="text-sm text-zinc-400">
                Jump to <a className="underline decoration-yellow-500/40 underline-offset-4" href="/errors/overload">System Overload</a>{' '}
                or <a className="underline decoration-yellow-500/40 underline-offset-4" href="/errors/lockdown">Security Lockdown</a> to
                simulate emergency response flows.
              </p>
            </div>
          </aside>
        </section>
      </div>
    </div>
  )
}
