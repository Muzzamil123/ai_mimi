import { useState } from 'react'

/** Collects optional feedback and rejects the current character. */
export function RejectionFeedbackForm({
  busy,
  onReject,
}: {
  busy: boolean
  onReject: (feedback: string) => void
}) {
  const [feedback, setFeedback] = useState('')

  return (
    <form
      className="auth-form"
      onSubmit={(e) => {
        e.preventDefault()
        onReject(feedback.trim())
      }}
    >
      <div className="field">
        <label htmlFor="rejection-feedback">What should change? (optional)</label>
        <textarea
          id="rejection-feedback"
          rows={3}
          value={feedback}
          onChange={(e) => setFeedback(e.target.value)}
          placeholder="e.g. make the character friendlier and younger"
        />
      </div>
      <button type="submit" className="danger" disabled={busy}>
        Reject &amp; regenerate later
      </button>
    </form>
  )
}
