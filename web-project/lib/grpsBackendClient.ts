const DEFAULT_BASE_URL = process.env.NEXT_PUBLIC_AUTOMATION_BASE_URL ?? 'http://localhost:8000'

export type SyncResponse = {
  updated: number
  created: number
}

export type LeaderboardEntry = {
  userId: number
  username: string
  rank: string | null
  points: number | null
  kos: number | null
  wos: number | null
  lastSyncedAt: string | null
}

export type LeaderboardRecords = {
  kos: Array<{ userId: number; username: string; kos: number | null }>
  wos: Array<{ userId: number; username: string; wos: number | null }>
}

async function request<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(`${DEFAULT_BASE_URL}${path}`, {
    ...init,
    headers: {
      'content-type': 'application/json',
      ...(init?.headers ?? {})
    },
    cache: 'no-store'
  })

  if (!response.ok) {
    const message = await response.text()
    throw new Error(`Automation request failed (${response.status}): ${message}`)
  }

  return (await response.json()) as T
}

export async function triggerRobloxSync(signature: string, payload: { activity: string; limit?: number; cursor?: string | null }): Promise<SyncResponse> {
  return request<SyncResponse>('/sync/roblox', {
    method: 'POST',
    body: JSON.stringify({
      activity: payload.activity,
      limit: payload.limit ?? 100,
      cursor: payload.cursor ?? null
    }),
    headers: {
      'x-grps-signature': signature
    }
  })
}

export async function fetchAutomationLeaderboard(limit = 30): Promise<LeaderboardEntry[]> {
  const params = new URLSearchParams({ limit: String(limit) })
  const payload = await request<{ players: LeaderboardEntry[] }>(`/leaderboard/top?${params.toString()}`)
  return payload.players
}

export async function fetchAutomationHealth(): Promise<{ status: string }> {
  return request<{ status: string }>('/health/live')
}

export async function fetchAutomationMetrics(): Promise<{ totalPlayers: number; updatedLastHour: number }> {
  return request<{ totalPlayers: number; updatedLastHour: number }>('/metrics/health')
}

export async function fetchAutomationRecords(limit = 5): Promise<LeaderboardRecords> {
  const params = new URLSearchParams({ limit: String(limit) })
  return request<LeaderboardRecords>(`/leaderboard/records?${params.toString()}`)
}
