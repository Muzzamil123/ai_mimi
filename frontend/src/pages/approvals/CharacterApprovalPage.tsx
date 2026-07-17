import { useCallback, useEffect, useState } from 'react'
import { useParams, useSearchParams } from 'react-router-dom'
import { toast } from 'sonner'
import {
  approvalImageUrl,
  approveViaToken,
  getApproval,
  rejectViaToken,
  type ApprovalRequest,
} from '../../api/approvals'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'invalid' } // unknown/tampered token (404)
  | { kind: 'error'; message: string }
  | { kind: 'loaded'; request: ApprovalRequest }

/**
 * Public, token-protected page reached from the character-approval email. It has
 * no authenticated session; the token in the URL is the authorization. Handles
 * every resolved state: actionable (approve/reject), already-processed, expired,
 * and superseded/cancelled.
 */
export function CharacterApprovalPage() {
  const { token } = useParams<{ token: string }>()
  const [searchParams] = useSearchParams()
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [busy, setBusy] = useState(false)
  // Prefill reject mode when the email's "Reject" link was used.
  const [rejecting, setRejecting] = useState(searchParams.get('intent') === 'reject')
  const [feedback, setFeedback] = useState('')

  const load = useCallback(async () => {
    if (!token) {
      setState({ kind: 'invalid' })
      return
    }
    try {
      const request = await getApproval(token)
      setState({ kind: 'loaded', request })
    } catch (err) {
      if ((err as { status?: number }).status === 404) {
        setState({ kind: 'invalid' })
        return
      }
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load the approval link') })
    }
  }, [token])

  useEffect(() => {
    void load()
  }, [load])

  const handleApprove = async () => {
    if (!token) return
    setBusy(true)
    try {
      const request = await approveViaToken(token)
      setState({ kind: 'loaded', request })
      toast.success('Character approved. Your project is ready!')
    } catch (err) {
      toast.error(getErrorMessage(err, 'Could not approve the character'))
      // Re-sync so a stale/expired/used link reflects its real state.
      void load()
    } finally {
      setBusy(false)
    }
  }

  const handleReject = async () => {
    if (!token) return
    setBusy(true)
    try {
      const request = await rejectViaToken(token, feedback.trim() || undefined)
      setState({ kind: 'loaded', request })
      toast.success('Character rejected. You can regenerate a new one in the project.')
    } catch (err) {
      toast.error(getErrorMessage(err, 'Could not reject the character'))
      void load()
    } finally {
      setBusy(false)
    }
  }

  if (state.kind === 'loading') {
    return <Loading label="Loading approval…" />
  }

  if (state.kind === 'invalid') {
    return (
      <EmptyState
        title="This link isn’t valid"
        description="The approval link is invalid or has already been replaced by a newer one. Open the project in the portal to review your character."
      />
    )
  }

  if (state.kind === 'error') {
    return <EmptyState title="Something went wrong" description={state.message} />
  }

  const { request } = state

  if (request.status === 'expired') {
    return (
      <EmptyState
        title="This approval link expired"
        description="No action was taken and your character is still waiting. Open the project in the portal to send a fresh approval link."
      />
    )
  }

  if (request.status === 'cancelled') {
    return (
      <EmptyState
        title="This link was superseded"
        description="A newer approval link was generated for this character. Please use the most recent email, or open the project in the portal."
      />
    )
  }

  if (request.status === 'approved') {
    return (
      <EmptyState
        title="Character approved 🎉"
        description={`“${request.character.name}” for “${request.project.name}” has been approved and is locked as the project’s reference character.`}
      />
    )
  }

  if (request.status === 'rejected') {
    return (
      <EmptyState
        title="Character rejected"
        description={`“${request.character.name}” for “${request.project.name}” was rejected. You can regenerate a new one in the project.`}
      />
    )
  }

  // status === 'pending' && actionable
  return (
    <section className="approval-page">
      <h1>Approve your character</h1>
      <p>
        Review the character <strong>{request.character.name}</strong> generated for your project{' '}
        <strong>{request.project.name}</strong>. No videos can be generated until it’s approved.
      </p>

      {request.character.has_image && token ? (
        <figure className="character-preview">
          <img
            src={approvalImageUrl(token)}
            alt={`Character ${request.character.name}`}
            className="character-preview__image"
          />
        </figure>
      ) : (
        <p className="muted">No preview image is available.</p>
      )}

      {request.character.description ? (
        <p className="muted">{request.character.description}</p>
      ) : null}

      {!rejecting ? (
        <div className="approval-actions">
          <button type="button" disabled={busy} onClick={() => void handleApprove()}>
            Approve character
          </button>
          <button type="button" className="danger" disabled={busy} onClick={() => setRejecting(true)}>
            Reject
          </button>
        </div>
      ) : (
        <form
          className="auth-form"
          onSubmit={(e) => {
            e.preventDefault()
            void handleReject()
          }}
        >
          <div className="field">
            <label htmlFor="approval-feedback">What should change? (optional)</label>
            <textarea
              id="approval-feedback"
              rows={3}
              value={feedback}
              onChange={(e) => setFeedback(e.target.value)}
              placeholder="e.g. make the character friendlier and younger"
            />
          </div>
          <div className="approval-actions">
            <button type="submit" className="danger" disabled={busy}>
              Confirm rejection
            </button>
            <button type="button" disabled={busy} onClick={() => setRejecting(false)}>
              Back
            </button>
          </div>
        </form>
      )}
    </section>
  )
}
