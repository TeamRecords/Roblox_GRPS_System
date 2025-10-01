export const metadata = {
  title: 'Leaderboard Rules | RLE Leaderboard'
}

export default function LeaderstatsRulesPage() {
  return (
    <article className="space-y-8 text-sm leading-relaxed text-slate-200">
      <header className="space-y-3">
        <p className="text-xs uppercase tracking-[0.3em] text-slate-400">Updated March 2024</p>
        <h2 className="text-3xl font-semibold text-white">Leaderboard Rules</h2>
        <p className="text-slate-300">
          The GRPS leaderboard is designed to celebrate authentic competitive play. These rules outline how standings are
          maintained, how misconduct is handled, and how you can compete fairly.
        </p>
      </header>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-white">1. Respect Platform Policies</h3>
        <p>
          Participation in the leaderboard requires full compliance with the official Roblox Terms of Use, Roblox Privacy
          Policy, Discord Terms of Service, and Discord Privacy Policy. Violations of these policies may result in removal
          from the leaderboard and associated communities.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-white">2. Legitimate Gameplay Only</h3>
        <p>
          Boosting, exploiting, macroing, or otherwise automating gameplay to inflate statistics is prohibited. Accounts
          found engaging in unfair tactics will have scores reset or be permanently banned from participation.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-white">3. Data Integrity</h3>
        <p>
          Leaderstats are synced directly from Roblox game servers. Attempting to tamper with API responses, interfering with
          data collection, or sharing false reports undermines the leaderboard and will be subject to disciplinary action.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-white">4. Community Conduct</h3>
        <p>
          Treat fellow competitors with respect on Roblox and Discord. Harassment, hate speech, and disruptive behavior are
          not tolerated. Moderators may suspend players from community spaces or the leaderboard as needed to maintain a safe
          environment.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-white">5. Reporting &amp; Appeals</h3>
        <p>
          Use the official GRPS support channels to report suspicious activity or leaderboard issues. Provide as much detail
          as possible. Appeals for disciplinary actions are reviewed by the moderation team and Roblox staff when required.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-white">6. Updates</h3>
        <p>
          These rules may be updated to reflect platform changes or new game modes. Continued participation after a revision
          signifies acceptance of the updated rules.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-white">Need Assistance?</h3>
        <p>
          Contact the GRPS moderation staff through our Discord server or Roblox group announcements for clarification about
          these rules or to request support.
        </p>
      </section>
    </article>
  )
}
