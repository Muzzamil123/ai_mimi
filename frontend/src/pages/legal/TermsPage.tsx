import { env } from '../../config/env'

/** Public terms of service. Generic but coherent; tailor before production launch. */
export function TermsPage() {
  return (
    <section className="legal-page">
      <h1>Terms of Service</h1>
      <p>
        By using {env.appName} you agree to these terms. Please read them carefully; if you do not
        agree, do not use the service.
      </p>

      <h2>Your account</h2>
      <p>
        You are responsible for the activity under your account and for keeping your credentials
        secure. Provide accurate information and notify us of any unauthorized use.
      </p>

      <h2>Acceptable use</h2>
      <ul>
        <li>Do not generate content that is unlawful, infringing, or violates others&apos; rights.</li>
        <li>Do not attempt to disrupt, overload, or reverse-engineer the service.</li>
        <li>Respect the usage and rate limits applied to protect the platform.</li>
      </ul>

      <h2>Content ownership</h2>
      <p>
        You retain rights to the ideas and media you create, subject to the terms of the underlying
        AI providers. You grant us the limited rights needed to process and store your content to
        provide the service.
      </p>

      <h2>Availability &amp; changes</h2>
      <p>
        The service is provided on an &quot;as is&quot; basis. We may perform maintenance, apply
        limits, or change features, and will make reasonable efforts to communicate significant
        changes.
      </p>

      <h2>Contact</h2>
      <p>
        Questions about these terms? Email{' '}
        <a href="mailto:support@aicvp.example">support@aicvp.example</a>.
      </p>
    </section>
  )
}
