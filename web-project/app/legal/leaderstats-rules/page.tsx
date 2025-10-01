export const metadata = {
  title: 'Leaderboard Rules | RLE Leaderboard'
}

export default function LeaderstatsRulesPage() {
  return (
    <article className="space-y-8 text-sm leading-relaxed text-zinc-200">
      <header className="space-y-3">
        <p className="text-xs uppercase tracking-[0.3em] text-zinc-500">Updated March 2024</p>
        <h2 className="text-3xl font-semibold text-yellow-100" data-signal>
          Leaderstats Rules
        </h2>
        <p className="text-zinc-400">
          Compliance with these rules is mandatory for remaining on the Roblox GRPS leaderboard. Violations can result in
          stat resets, suspensions, or permanent removal.
        </p>
      </header>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Fair Combat</h3>
        <p>
          Exploits, automation, or teaming with known cheaters is strictly forbidden. Reports should be submitted via the
          Discord relay with supporting evidence.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Stat Integrity</h3>
        <p>
          Leaderstats are mirrored directly from Roblox gameplay. Manual stat edits or data tampering attempts will be
          detected and lead to immediate removal.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Identity Verification</h3>
        <p>
          Users must maintain consistent Roblox usernames. Name changes must be announced to moderators to avoid duplicate or
          conflicting entries.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Communication</h3>
        <p>
          Official announcements and dispute resolutions occur via the GRPS Discord server. Stay subscribed to updates to
          avoid missing policy changes.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Consequences</h3>
        <p>
          Penalties include stat rollbacks, temporary suspensions, or permanent bans depending on severity. Repeat offenders
          may be reported to Roblox for further enforcement.
        </p>
      </section>
    </article>
  )
}
