export async function GET() {
  const kos = [
    { userId: 2001, username: "Alpha", kos: 1245 },
    { userId: 2002, username: "Bravo", kos: 1190 },
    { userId: 2003, username: "Charlie", kos: 1104 },
    { userId: 2004, username: "Delta", kos: 1060 },
    { userId: 2005, username: "Echo", kos: 1002 },
  ];
  const wos = [
    { userId: 3001, username: "Orion", wos: 980 },
    { userId: 3002, username: "Nova", wos: 940 },
    { userId: 3003, username: "Vega", wos: 900 },
    { userId: 3004, username: "Rhea", wos: 870 },
    { userId: 3005, username: "Zeph", wos: 850 },
  ];
  return new Response(JSON.stringify({ kos, wos }), { headers: { "content-type": "application/json" } });
}
