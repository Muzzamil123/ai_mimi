import { env } from '../../config/env'

/** Public privacy policy. Generic but coherent; tailor before production launch. */
export function PrivacyPage() {
  return (
    <section className="legal-page">
      <h1>Privacy Policy</h1>
      <p>
        This policy explains what data {env.appName} collects, how it is used, and the choices you
        have. It applies to the web platform and its APIs.
      </p>

      <h2>Data we handle</h2>
      <ul>
        <li>
          <strong>Account data</strong> — your name and email address, used to sign you in and to
          send workflow notifications (character approvals, generation results).
        </li>
        <li>
          <strong>Project content</strong> — the projects, character descriptions, video ideas,
          transcripts, prompts, and generated media you create.
        </li>
        <li>
          <strong>Operational data</strong> — provider usage and estimated cost records, delivery
          logs, and audit entries for sensitive actions, used to run and secure the service.
        </li>
      </ul>

      <h2>AI providers</h2>
      <p>
        To generate characters, prompts, transcripts, and videos we send the relevant content to
        third-party AI providers. We never share your password, and provider API credentials are
        stored encrypted and are never exposed to the browser.
      </p>

      <h2>Retention</h2>
      <p>
        Generated assets are retained according to the platform&apos;s configured retention window
        and are then purged automatically. You can request deletion of your account at any time.
      </p>

      <h2>Account deletion</h2>
      <p>
        Deleting your account immediately ends your sessions and schedules permanent removal of your
        projects and generated media, and anonymization of your personal information. This action is
        irreversible.
      </p>

      <h2>Contact</h2>
      <p>
        Questions about this policy? Email{' '}
        <a href="mailto:support@aicvp.example">support@aicvp.example</a>.
      </p>
    </section>
  )
}
