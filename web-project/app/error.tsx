'use client'

import { useEffect } from 'react'

type GlobalErrorProps = {
  error: Error & { digest?: string }
  reset: () => void
}

export default function GlobalError({ error, reset }: GlobalErrorProps) {
  useEffect(() => {
    console.error('Imperial command caught a runtime error', error)
  }, [error])

  return (
    <div className="flex min-h-screen items-center justify-center bg-[#020204] px-6 py-24 text-center text-zinc-200">
      <div className="panel-emphasis max-w-xl space-y-6 p-10">
        <p className="text-sm uppercase tracking-[0.35em] text-red-400">Critical failure</p>
        <h1 className="text-4xl font-semibold text-yellow-100" data-signal>
          Unexpected anomaly detected
        </h1>
        <p className="text-sm leading-relaxed text-zinc-400">
          The command deck encountered an unrecoverable runtime breach. The stack trace has been recorded. Attempt a soft
          reboot or redeploy via Discord support channels if the signal does not recover.
        </p>
        {error?.digest && (
          <p className="text-xs text-zinc-600">Reference code: {error.digest}</p>
        )}
        <div className="flex flex-wrap justify-center gap-4 text-sm">
          <button
            type="button"
            onClick={() => reset()}
            className="rounded-full bg-yellow-500/20 px-5 py-2 font-medium text-yellow-200 transition hover:bg-yellow-500/30"
          >
            Retry operation
          </button>
          <a
            href="https://discord.gg/cXKEdAKdWv"
            target="_blank"
            rel="noreferrer noopener"
            className="rounded-full bg-zinc-800 px-5 py-2 font-medium text-zinc-200 transition hover:bg-zinc-700"
          >
            Contact Discord relay
          </a>
        </div>
      </div>
    </div>
  )
}
