export async function GET() {
  // Example data; replace with real datastore snapshot
  const players = Array.from({ length: 25 }).map((_, i) => ({
    userId: 1000 + i,
    username: `Player${i+1}`,
    rank: i < 3 ? "Arc Lieutenant II" : i < 10 ? "Thunder Sergeant I" : "Volt Specialist II",
    points: 5000 - i * 100,
    kos: 1000 - i * 10,
    wos: 200 + i * 5,
  }));
  return new Response(JSON.stringify({ players }), { headers: { "content-type": "application/json" } });
}
