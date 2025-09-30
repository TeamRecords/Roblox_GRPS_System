export async function GET(_req, { params }) {
  const { userId } = params;
  const data = {
    userId,
    username: `User${userId}`,
    rank: "Thunder Sergeant II",
    points: 3450,
    kos: 420,
    wos: 220,
    history: [
      { date: "2025-09-01", change: +25, reason: "Operation Complete" },
      { date: "2025-09-02", change: +15, reason: "Training Complete" },
      { date: "2025-09-05", change: -2, reason: "WO" },
    ]
  };
  return new Response(JSON.stringify(data), { headers: { "content-type": "application/json" } });
}
