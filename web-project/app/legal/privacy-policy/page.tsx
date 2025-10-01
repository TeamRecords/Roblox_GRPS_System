export const metadata = {
  title: 'Privacy Policy | RLE Leaderboard'
}

export default function PrivacyPolicyPage() {
  return (
    <article className="space-y-8 text-sm leading-relaxed text-zinc-200">
      <header className="space-y-3">
        <p className="text-xs uppercase tracking-[0.3em] text-amber-400">Updated March 2024</p>
        <h2 className="text-3xl font-semibold text-white">Privacy Policy</h2>
        <p className="text-zinc-300">
          This Privacy Policy explains how the Roblox GRPS leaderboard ("we", "our", "us") collects, uses, and shares data
          related to your participation in the leaderboard experience.
        </p>
      </header>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-amber-300">1. Data We Collect</h3>
        <p>
          We collect leaderboard-specific data provided through Roblox services, including your Roblox username, user ID,
          rank, points, knockouts, wipeouts, and relevant timestamps. We do not collect passwords or sensitive personal data
          from your Roblox account.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-amber-300">2. How We Use Data</h3>
        <p>
          Your statistics are used to calculate standings, display record holders, and maintain historical performance. We may
          analyze aggregated data to improve matchmaking, detect suspicious activity, and provide insights to the GRPS
          community.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-amber-300">3. Data Sharing</h3>
        <p>
          Leaderboard data is publicly viewable within the GRPS experience and associated web properties. We do not sell or
          rent data to third parties. We may share data with Roblox Corporation or platform partners if required to enforce
          policy compliance or respond to legal requests.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-amber-300">4. Retention &amp; Security</h3>
        <p>
          Data is retained as long as necessary to operate the leaderboard or fulfill regulatory obligations. We implement
          safeguards such as access controls and monitoring to protect leaderboard data from unauthorized use.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-amber-300">5. Your Choices</h3>
        <p>
          If you wish to have your data removed from public display, contact the GRPS moderation team. Removal requests are
          handled in accordance with Roblox policies and may require verification of account ownership.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-amber-300">6. Children&apos;s Privacy</h3>
        <p>
          The leaderboard follows Roblox community standards designed to protect younger audiences. We do not knowingly
          collect additional personal information from children under 13 beyond what Roblox provides through platform APIs.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-amber-300">Contact</h3>
        <p>
          Privacy questions can be directed to the GRPS moderation team via our official Discord server or through the
          support contact listed in the Roblox experience description.
        </p>
      </section>
    </article>
  )
}
