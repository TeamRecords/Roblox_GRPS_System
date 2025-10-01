export const metadata = {
  title: 'Privacy Policy | RLE Leaderboard'
}

export default function PrivacyPolicyPage() {
  return (
    <article className="space-y-8 text-sm leading-relaxed text-zinc-200">
      <header className="space-y-3">
        <p className="text-xs uppercase tracking-[0.3em] text-zinc-500">Updated March 2024</p>
        <h2 className="text-3xl font-semibold text-yellow-100" data-signal>
          Privacy Policy
        </h2>
        <p className="text-zinc-400">
          This Privacy Policy explains how the Roblox GRPS leaderboard ("we", "our") collects, stores, and protects data
          when you interact with the Service.
        </p>
      </header>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Data We Collect</h3>
        <p>
          We synchronise Roblox usernames, user IDs, ranks, points, knockouts, wipeouts, and timestamps associated with
          leaderboard activity. Optional Discord handles submitted through support forms may also be stored.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">How Data Is Used</h3>
        <p>
          Data fuels leaderboard standings, record tracking, and moderation investigations. Aggregated snapshots are retained
          to detect anomalies, verify reports, and provide historical analytics to administrators.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Data Sharing</h3>
        <p>
          We do not sell player data. Limited details may be shared with trusted Roblox developers or Discord moderators to
          resolve disputes, enforce rules, or comply with legal requirements.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Security</h3>
        <p>
          Leaderstats and snapshots are stored in secure Postgres Neon databases. Access is restricted and logged. Data in
          transit is encrypted via HTTPS, and Discord webhooks are processed server-side to protect tokens.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Retention</h3>
        <p>
          We retain leaderboard entries as long as the Roblox experience remains active. Archived snapshots may be retained
          for auditing and anti-cheat reviews, after which they are deleted or anonymised.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Your Rights</h3>
        <p>
          Players may request corrections or removal of incorrect leaderstats via the official Discord server or Roblox
          support channels. We may require verification before fulfilling sensitive requests.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Contact</h3>
        <p>
          Contact the GRPS privacy lead through our Discord relay or by using the communication methods listed in the Roblox
          experience description.
        </p>
      </section>
    </article>
  )
}
