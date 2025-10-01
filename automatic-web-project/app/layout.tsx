import type { Metadata } from 'next'

import './globals.css'

export const metadata: Metadata = {
  title: 'RLE Automation API',
  description: 'Operational API surface for Robloxian Lightning Empire GRPS automation.',
}

export default function RootLayout({ children }: { children: React.ReactNode }) {
  return (
    <html lang="en">
      <body>{children}</body>
    </html>
  )
}
