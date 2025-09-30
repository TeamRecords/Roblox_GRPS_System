async function fetchLeaderboard() {
  // Replace with your public API endpoint connected to GRPS
  const res = await fetch(process.env.NEXT_PUBLIC_GRPS_API + "/leaderboard/top", { cache: "no-store" });
  if (!res.ok) return { players: [] };
  return res.json();
}
async function fetchTopKOsWOs() {
  const res = await fetch(process.env.NEXT_PUBLIC_GRPS_API + "/leaderboard/records", { cache: "no-store" });
  if (!res.ok) return { kos: [], wos: [] };
  return res.json();
}

export default async function Home() {
  const data = await fetchLeaderboard();
  const records = await fetchTopKOsWOs();
  return (
    <main className="container mx-auto p-6 space-y-8">
      <header className="space-y-2">
        <h1 className="text-3xl font-bold">RLE Global Leaderboard</h1>
        <p className="text-slate-400">Top players across Roblox experiences linked to RLE.</p>
      </header>

      <section>
        <h2 className="text-xl font-semibold mb-3">Top 25 Players</h2>
        <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-3">
          {data.players?.map((p, i) => (
            <div key={p.userId} className="rounded-xl border border-slate-800 p-4">
              <div className="text-slate-400">#{i+1}</div>
              <div className="text-lg font-semibold">{p.username}</div>
              <div className="text-sm text-slate-400">Rank: {p.rank} · Points: {p.points}</div>
              <div className="text-sm text-slate-500">KOs: {p.kos} · WOs: {p.wos}</div>
            </div>
          ))}
        </div>
      </section>

      <section className="grid md:grid-cols-2 gap-6">
        <div>
          <h2 className="text-xl font-semibold mb-3">Top KOs (All-time)</h2>
          <ol className="space-y-2 list-decimal list-inside">
            {records.kos?.slice(0,5).map((r)=> (
              <li key={r.userId} className="text-slate-200">{r.username} — {r.kos}</li>
            ))}
          </ol>
        </div>
        <div>
          <h2 className="text-xl font-semibold mb-3">Top WOs (All-time)</h2>
          <ol className="space-y-2 list-decimal list-inside">
            {records.wos?.slice(0,5).map((r)=> (
              <li key={r.userId} className="text-slate-200">{r.username} — {r.wos}</li>
            ))}
          </ol>
        </div>
      </section>
    </main>
  );
}
