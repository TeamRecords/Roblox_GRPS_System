export const metadata = {
  title: 'Terms of Service | RLE Leaderboard'
}

export default function TermsOfServicePage() {
  return (
    <article className="space-y-8 text-sm leading-relaxed text-zinc-200">
      <header className="space-y-3">
        <p className="text-xs uppercase tracking-[0.3em] text-zinc-500">Updated March 2024</p>
        <h2 className="text-3xl font-semibold text-yellow-100" data-signal>
          Terms of Service
        </h2>
        <p className="text-zinc-400">
          These Terms of Service ("Terms") govern your access to and use of the Roblox GRPS leaderboard (the "Service").
          By accessing or interacting with the Service you agree to be bound by these Terms.
        </p>
      </header>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">1. Eligibility</h3>
        <p>
          The Service is intended for Roblox players who participate in the GRPS experience. You must comply with the Roblox
          Terms of Use, Community Rules, and any applicable platform policies. Users who are banned or suspended from Roblox
          or GRPS may have their leaderboard access revoked.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">2. Account Data</h3>
        <p>
          Leaderboard standings are determined using in-game performance metrics, including rank, points, knockouts, and
          wipeouts. You consent to GRPS collecting and displaying this data in accordance with the Roblox privacy and data
          usage guidelines. You are responsible for keeping your Roblox account secure.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">3. Fair Play &amp; Enforcement</h3>
        <p>
          Cheating, exploiting, or manipulating game systems to artificially increase leaderboard standing is prohibited. We
          reserve the right to remove entries, reset statistics, or restrict access without notice if suspicious activity is
          detected. Reports can be submitted through the official GRPS support channels.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">4. Service Availability</h3>
        <p>
          We strive to maintain accurate and up-to-date leaderstats but do not guarantee uninterrupted access. Maintenance,
          updates, or platform outages may affect availability. Data displayed may lag behind in-game changes during periods
          of high activity.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">5. Limitation of Liability</h3>
        <p>
          The Service is provided on an "as is" basis. To the fullest extent permitted by law, GRPS and its collaborators
          disclaim liability for any indirect, incidental, or consequential damages arising from use of the leaderboard.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">6. Changes</h3>
        <p>
          We may modify these Terms to reflect updates to the Service or legal requirements. Material changes will be
          communicated through the leaderboard site or GRPS channels. Continued use of the Service after an update constitutes
          acceptance of the revised Terms.
        </p>
      </section>

      <section className="space-y-3">
        <h3 className="text-lg font-semibold text-yellow-100">Contact</h3>
        <p>
          For questions about these Terms, reach out to the GRPS moderation team via our official Discord server or through
          the support email listed in the Roblox experience description.
        </p>
      </section>
    </article>
  )
}
