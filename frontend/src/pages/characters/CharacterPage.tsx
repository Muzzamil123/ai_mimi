import { useCallback, useEffect, useRef, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import {
  approveCharacter,
  createCharacter,
  deleteCharacter,
  generateCharacter,
  getCharacter,
  rejectCharacter,
  resetCharacter,
  updateCharacter,
  type Character,
  type CharacterInput,
} from '../../api/characters'
import { useAuth } from '../../auth/AuthContext'
import { CharacterStatusBadge } from '../../components/CharacterStatusBadge'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'
import { CharacterPreview } from './CharacterPreview'
import { CharacterSetupForm } from './CharacterSetupForm'
import { RejectionFeedbackForm } from './RejectionFeedbackForm'

const POLL_INTERVAL_MS = 3000

type LoadState =
  | { kind: 'loading' }
  | { kind: 'setup' } // no character yet
  | { kind: 'ready'; character: Character }
  | { kind: 'not-found' }
  | { kind: 'error'; message: string }

export function CharacterPage() {
  const { id } = useParams<{ id: string }>()
  const projectId = Number(id)
  const { isAdmin } = useAuth()
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [busy, setBusy] = useState(false)
  const [editing, setEditing] = useState(false)

  const load = useCallback(async () => {
    try {
      const character = await getCharacter(projectId)
      setState({ kind: 'ready', character })
    } catch (err) {
      const status = (err as { status?: number }).status
      if (status === 404) {
        // Distinguish "project not found" from "character not created yet".
        // The API returns 404 for both; the project page guards project access,
        // so here 404 means no character exists yet — show the setup form.
        setState({ kind: 'setup' })
        return
      }
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load character') })
    }
  }, [projectId])

  useEffect(() => {
    void load()
  }, [load])

  // Poll while a generation is in flight so the UI advances automatically.
  const currentStatus = state.kind === 'ready' ? state.character.status : null
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null)
  useEffect(() => {
    if (currentStatus !== 'generating') return
    pollRef.current = setInterval(() => void load(), POLL_INTERVAL_MS)
    return () => {
      if (pollRef.current) clearInterval(pollRef.current)
    }
  }, [currentStatus, load])

  const run = async (action: () => Promise<unknown>, errorMessage: string) => {
    setBusy(true)
    try {
      await action()
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, errorMessage))
    } finally {
      setBusy(false)
    }
  }

  const onCreate = async (input: CharacterInput) => {
    try {
      const character = await createCharacter(projectId, input)
      toast.success('Character saved. You can now generate it.')
      setState({ kind: 'ready', character })
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to save character'))
    }
  }

  const onEdit = async (input: CharacterInput) => {
    try {
      const character = await updateCharacter(projectId, input)
      toast.success('Character updated')
      setEditing(false)
      setState({ kind: 'ready', character })
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to update character'))
    }
  }

  if (state.kind === 'loading') return <Loading label="Loading character…" />

  if (state.kind === 'error') {
    return (
      <EmptyState
        title="Unable to load character"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  if (state.kind === 'not-found') {
    return (
      <EmptyState
        title="Project not found"
        description="This project does not exist or you do not have access to it."
        action={<Link to="/projects">Back to projects</Link>}
      />
    )
  }

  const backLink = (
    <p className="auth-links">
      <Link to={`/projects/${projectId}`}>Back to project</Link>
    </p>
  )

  if (state.kind === 'setup') {
    return (
      <section className="auth-card">
        <h1>Set up your character</h1>
        <p className="muted">
          Each project has exactly one character. Describe it, then generate an image with Gemini.
        </p>
        <CharacterSetupForm submitLabel="Save character" onSubmit={onCreate} />
        {backLink}
      </section>
    )
  }

  const { character } = state

  return (
    <section className="character-page">
      <div className="page-header">
        <div className="page-header__title">
          <h1>{character.name}</h1>
          <CharacterStatusBadge status={character.status} />
        </div>
      </div>

      {character.description && <p>{character.description}</p>}

      {character.status === 'pending' && !editing && (
        <div className="character-actions">
          <button type="button" disabled={busy} onClick={() => void run(() => generateCharacter(projectId), 'Unable to start generation')}>
            Generate character
          </button>
          <button type="button" disabled={busy} onClick={() => setEditing(true)}>
            Edit
          </button>
          <button
            type="button"
            className="danger"
            disabled={busy}
            onClick={() => {
              if (window.confirm('Delete this character setup?')) {
                void run(async () => {
                  await deleteCharacter(projectId)
                  setState({ kind: 'setup' })
                }, 'Unable to delete character')
              }
            }}
          >
            Delete
          </button>
        </div>
      )}

      {character.status === 'pending' && editing && (
        <>
          <h2>Edit character</h2>
          <CharacterSetupForm
            submitLabel="Save changes"
            initial={{
              name: character.name,
              description: character.description,
              attributes: character.attributes,
              style_preferences: character.style_preferences,
            }}
            onSubmit={onEdit}
          />
          <button type="button" onClick={() => setEditing(false)}>
            Cancel
          </button>
        </>
      )}

      {character.status === 'generating' && (
        <div className="generation-progress" role="status">
          <Loading label="Generating your character — this can take a moment…" />
          <p className="muted">You&apos;ll be emailed when it&apos;s ready to review.</p>
        </div>
      )}

      {character.status === 'awaiting_approval' && (
        <div className="character-review">
          <CharacterPreview projectId={projectId} character={character} />
          <div className="character-actions">
            <button type="button" disabled={busy} onClick={() => void run(() => approveCharacter(projectId), 'Unable to approve')}>
              Approve character
            </button>
          </div>
          <RejectionFeedbackForm
            busy={busy}
            onReject={(feedback) => void run(() => rejectCharacter(projectId, feedback || undefined), 'Unable to reject')}
          />
        </div>
      )}

      {character.status === 'rejected' && (
        <div className="character-rejected">
          {character.rejection_feedback && (
            <p>
              <strong>Your feedback:</strong> {character.rejection_feedback}
            </p>
          )}
          <button type="button" disabled={busy} onClick={() => void run(() => generateCharacter(projectId), 'Unable to regenerate')}>
            Regenerate character
          </button>
        </div>
      )}

      {character.status === 'failed' && (
        <div className="character-failed">
          <p className="field-error">Generation failed: {character.failure_reason ?? 'unknown error'}</p>
          <button type="button" disabled={busy} onClick={() => void run(() => generateCharacter(projectId), 'Unable to retry')}>
            Try again
          </button>
        </div>
      )}

      {character.status === 'approved' && (
        <div className="character-approved">
          <CharacterPreview projectId={projectId} character={character} />
          <p className="approval-status">
            ✓ Approved and locked. This character will be used for every video in this project.
          </p>
          {isAdmin && (
            <button
              type="button"
              className="danger"
              disabled={busy}
              onClick={() => {
                if (window.confirm('Admin reset: unlock and clear this character?')) {
                  void run(() => resetCharacter(projectId), 'Unable to reset')
                }
              }}
            >
              Reset character (admin)
            </button>
          )}
        </div>
      )}

      {backLink}
    </section>
  )
}
