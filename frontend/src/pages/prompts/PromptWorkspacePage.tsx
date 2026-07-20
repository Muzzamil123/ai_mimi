import { useCallback, useEffect, useRef, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import {
  approvePrompt,
  generatePrompt,
  listPrompts,
  savePromptVersion,
  type Prompt,
} from '../../api/prompts'
import { getVideo, type VideoDetail } from '../../api/videos'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { PromptStatusBadge } from '../../components/PromptStatusBadge'
import { getErrorMessage } from '../../lib/errors'

const POLL_INTERVAL_MS = 3000

/**
 * The version the workspace acts on: the newest non-superseded version. This
 * includes a `failed` version so its failure is surfaced (the API returns
 * versions newest-first).
 */
function currentPrompt(prompts: Prompt[]): Prompt | null {
  return prompts.find((p) => p.status !== 'superseded') ?? null
}

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; video: VideoDetail; prompts: Prompt[] }
  | { kind: 'not-found' }
  | { kind: 'error'; message: string }

export function PromptWorkspacePage() {
  const { id, videoId } = useParams<{ id: string; videoId: string }>()
  const projectId = Number(id)
  const vId = Number(videoId)

  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [busy, setBusy] = useState(false)
  const [draft, setDraft] = useState('')
  const [compareId, setCompareId] = useState<number | null>(null)

  const load = useCallback(
    async (options: { silent?: boolean } = {}) => {
      if (!options.silent) setState({ kind: 'loading' })
      try {
        const [video, { prompts }] = await Promise.all([
          getVideo(projectId, vId),
          listPrompts(projectId, vId),
        ])
        setState({ kind: 'ready', video, prompts })
        setDraft(currentPrompt(prompts)?.content ?? '')
      } catch (err) {
        const status = (err as { status?: number }).status
        if (status === 404) {
          setState({ kind: 'not-found' })
          return
        }
        setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load prompts') })
      }
    },
    [projectId, vId],
  )

  useEffect(() => {
    void load()
  }, [load])

  // Poll while a generation is in flight so the prompt appears automatically.
  const current = state.kind === 'ready' ? currentPrompt(state.prompts) : null
  const generating = current?.status === 'generating'
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null)
  useEffect(() => {
    if (!generating) return
    pollRef.current = setInterval(() => void load({ silent: true }), POLL_INTERVAL_MS)
    return () => {
      if (pollRef.current) clearInterval(pollRef.current)
    }
  }, [generating, load])

  const run = async (action: () => Promise<unknown>, errorMessage: string) => {
    setBusy(true)
    try {
      await action()
      await load({ silent: true })
    } catch (err) {
      toast.error(getErrorMessage(err, errorMessage))
    } finally {
      setBusy(false)
    }
  }

  const onGenerate = () =>
    run(async () => {
      await generatePrompt(projectId, vId)
      toast.success('Generating prompt…')
    }, 'Unable to start prompt generation')

  const onSave = () =>
    run(async () => {
      await savePromptVersion(projectId, vId, draft)
      toast.success('Saved as a new version')
    }, 'Unable to save prompt')

  const onApprove = (promptId: number) =>
    run(async () => {
      await approvePrompt(projectId, vId, promptId)
      toast.success('Prompt approved')
    }, 'Unable to approve prompt')

  const onCopy = async (content: string) => {
    try {
      await navigator.clipboard.writeText(content)
      toast.success('Copied to clipboard')
    } catch {
      toast.error('Could not copy to clipboard')
    }
  }

  if (state.kind === 'loading') return <Loading label="Loading prompt…" />

  if (state.kind === 'not-found') {
    return (
      <EmptyState
        title="Video not found"
        description="This video does not exist or you do not have access to it."
        action={<Link to={`/projects/${projectId}/videos`}>Back to videos</Link>}
      />
    )
  }

  if (state.kind === 'error') {
    return (
      <EmptyState
        title="Unable to load prompt"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  const { video, prompts } = state
  const backLink = (
    <p className="auth-links">
      <Link to={`/projects/${projectId}/videos/${vId}`}>Back to video</Link>
    </p>
  )

  if (!video.idea_present) {
    return (
      <section className="prompt-workspace">
        <h1>Prompt</h1>
        <EmptyState
          title="Add an idea first"
          description="Type or record an idea for this video before generating a prompt."
          action={<Link to={`/projects/${projectId}/videos/${vId}`}>Add an idea</Link>}
        />
        {backLink}
      </section>
    )
  }

  const compareTarget = compareId ? prompts.find((p) => p.id === compareId) : null

  return (
    <section className="prompt-workspace">
      <div className="page-header">
        <div className="page-header__title">
          <h1>Prompt — {video.title}</h1>
          {current && <PromptStatusBadge status={current.status} />}
        </div>
      </div>

      {!current && (
        <div className="prompt-empty">
          <p className="muted">No prompt yet. Generate one from this video&apos;s idea with OpenAI.</p>
          <button type="button" disabled={busy} onClick={() => void onGenerate()}>
            Generate prompt
          </button>
        </div>
      )}

      {generating && (
        <div className="generation-progress" role="status">
          <Loading label="Generating your prompt…" />
        </div>
      )}

      {current && current.status === 'failed' && (
        <div className="prompt-failed">
          <p className="field-error">Generation failed: {current.failure_reason ?? 'unknown error'}</p>
          <button type="button" disabled={busy} onClick={() => void onGenerate()}>
            Try again
          </button>
        </div>
      )}

      {current && (current.status === 'draft' || current.status === 'approved') && (
        <div className="prompt-editor">
          <h2>
            Version {current.version}
            {current.active && <span className="muted"> · active</span>}
          </h2>
          <textarea
            rows={8}
            value={draft}
            onChange={(event) => setDraft(event.target.value)}
            aria-label="Prompt content"
          />
          <div className="character-actions">
            <button type="button" disabled={busy} onClick={() => void onSave()}>
              Save as new version
            </button>
            {current.status !== 'approved' && (
              <button type="button" disabled={busy} onClick={() => void onApprove(current.id)}>
                Approve
              </button>
            )}
            <button type="button" disabled={busy} onClick={() => void onCopy(draft)}>
              Copy
            </button>
            <button type="button" disabled={busy} onClick={() => void onGenerate()}>
              Regenerate
            </button>
          </div>
          {current.input_tokens != null && (
            <p className="muted">
              Usage: {current.input_tokens} in / {current.output_tokens} out tokens
              {current.estimated_cost != null && ` · ~$${current.estimated_cost}`}
            </p>
          )}
        </div>
      )}

      {prompts.length > 0 && (
        <div className="prompt-history">
          <h2>Version history</h2>
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Version</th>
                  <th>Status</th>
                  <th>Source</th>
                  <th>Created</th>
                  <th>Compare</th>
                </tr>
              </thead>
              <tbody>
                {prompts.map((prompt) => (
                  <tr key={prompt.id}>
                    <td>
                      {prompt.version}
                      {prompt.active && <span className="muted"> · active</span>}
                    </td>
                    <td>
                      <PromptStatusBadge status={prompt.status} />
                    </td>
                    <td>{prompt.provider ?? '—'}</td>
                    <td>{new Date(prompt.created_at).toLocaleString()}</td>
                    <td>
                      <button
                        type="button"
                        onClick={() => setCompareId(compareId === prompt.id ? null : prompt.id)}
                      >
                        {compareId === prompt.id ? 'Hide' : 'View'}
                      </button>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>

          {compareTarget && (
            <div className="prompt-compare">
              <h3>Compare</h3>
              <div className="prompt-compare__columns">
                {current && current.id !== compareTarget.id && (
                  <div className="prompt-compare__column">
                    <h4>
                      Version {current.version} <span className="muted">(current)</span>
                    </h4>
                    <pre className="prompt-content">{current.content ?? '(no content)'}</pre>
                  </div>
                )}
                <div className="prompt-compare__column">
                  <h4>Version {compareTarget.version}</h4>
                  <pre className="prompt-content">{compareTarget.content ?? '(no content)'}</pre>
                </div>
              </div>
            </div>
          )}
        </div>
      )}

      {backLink}
    </section>
  )
}
