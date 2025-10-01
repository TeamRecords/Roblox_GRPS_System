import { NextResponse } from 'next/server'
import { fetchRecordHolders } from '@/lib/leaderboard'

export async function GET() {
  try {
    const records = await fetchRecordHolders(5)

    return NextResponse.json(records)
  } catch (error) {
    console.error('Failed to fetch record holders', error)
    return NextResponse.json(
      { error: 'Unable to load record holders at this time.' },
      {
        status: 500
      }
    )
  }
}
