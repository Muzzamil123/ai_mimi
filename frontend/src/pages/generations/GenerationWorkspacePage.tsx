import { useCallback, useEffect, useRef, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import { getVideo, type VideoDetail } from '../../api/videos'
import {
  cancelVideoGeneration,
  listVideoGenerations,
  retryVideoGeneration,
  startVideoGeneration,
  type VideoGeneration,
} from '../../api/videoGenerations'
import { EmptyState } from '../../components/EmptyState'
import { GenerationStatusBadge } from '../../components/GenerationStatusBadge'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

const POLL_INTERVAL_MS = 3000

function isActive(video: VideoDetail, generations: VideoGeneration[]): boolean {
  if (video.status === 'queued' || video.status === 'generating') return true
  return generations.some((g) => g.status === 'pending' || g.status === 'processing')
}

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; video: VideoDetail; generations: VideoGeneration[] }
  | { kind: 'not-found' }
  | { kind: 'error'; message: string }

export function GenerationWorkspacePage() {
  const { id, videoId } = useParams<{ id: string; videoId: string }>()
  const projectId = Number(id)
  const vId = Number(videoId)

  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [busy, setBusy] = useState(false)

  const load = useCallback(
    async (options: { silent?: boolean } = {}) => {
      if (!options.silent) setState({ kind: 'loading' })
      try {
        const [video, { video_generations }] = await Promise.all([
          getVideo(projectId, vId),
          listVideoGenerations(projectId, vId),
        ])
        setState({ kind: 'ready', video, generations: video_generations })
      } catch (err) {
        const status = (err as { status?: number }).status
        if (status === 404) {
          setState({ kind: 'not-found' })
          return
        }
        setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load generation') })
      }
    },
    [projectId, vId],
  )

  useEffect(() => {
    void load()
  }, [load])

  // Poll while the batch is running so statuses advance automatically.
  const active = state.kind === 'ready' && isActive(state.video, state.generations)
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null)
  useEffect(() => {
    if (!active) return
    pollRef.current = setInterval(() => void load({ silent: true }), POLL_INTERVAL_MS)
    return () => {
      if (pollRef.current) clearInterval(pollRef.current)
    }
  }, [active, load])

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

  const onStart = () =>
    run(async () => {
      await startVideoGeneration(projectId, vId)
      toast.success('Generation started — creating four outputs…')
    }, 'Unable to start generation')

  const onRetry = (generationId: number) =>
    run(async () => {
      await retryVideoGeneration(projectId, vId, generationId)
      toast.success('Retrying output…')
    }, 'Unable to retry output')

  const onCancel = () => {
    if (!window.confirm('Cancel the in-progress generation?')) return
    void run(async () => {
      await cancelVideoGeneration(projectId, vId)
      toast.success('Generation cancelled')
    }, 'Unable to cancel generation')
  }

  if (state.kind === 'loading') return <Loading label="Loading generation…" />

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
        title="Unable to load generation"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  const { video, generations } = state
  const backLink = (
    <p className="auth-links">
      <Link to={`/projects/${projectId}/videos/${vId}`}>Back to video</Link>
    </p>
  )

  // A prompt must be approved before generation (video reaches prompt_ready).
  const canStart = video.status === 'prompt_ready' && generations.length === 0
  const notReady = generations.length === 0 && video.status !== 'prompt_ready'
  const anyFailed = generations.some((g) => g.status === 'failed')

  if (notReady) {
    return (
      <section className="generation-workspace">
        <h1>Generate videos</h1>
        <EmptyState
          title="Approve a prompt first"
          description="Generate and approve a prompt for this video before creating videos."
          action={<Link to={`/projects/${projectId}/videos/${vId}/prompt`}>Go to prompt</Link>}
        />
        {backLink}
      </section>
    )
  }

  return (
    <section className="generation-workspace">
      <div className="page-header">
        <h1>Generate videos — {video.title}</h1>
        {isActive(video, generations) && (
          <button type="button" className="danger" disabled={busy} onClick={onCancel}>
            Cancel
          </button>
        )}
      </div>

      {canStart && (
        <div className="generation-confirm">
          <p>
            This creates <strong>four 15-second outputs</strong> — two 3:4 and two 9:16 — using the
            project&apos;s approved character and this video&apos;s approved prompt.
          </p>
          <button type="button" disabled={busy} onClick={() => void onStart()}>
            Start generation
          </button>
        </div>
      )}

      {anyFailed && (
        <p className="field-error" role="status">
          Some outputs failed. You can retry them individually below.
        </p>
      )}

      {generations.length > 0 && (
        <div className="generation-grid">
          {generations.map((generation) => (
            <div className="generation-card" key={generation.id} data-status={generation.status}>
              <div className="generation-card__header">
                <span className="generation-card__label">{generation.label}</span>
                <GenerationStatusBadge status={generation.status} />
              </div>

              {generation.status === 'processing' && (
                <div className="generation-card__progress" aria-label="progress">
                  <div
                    className="generation-card__progress-bar"
                    style={{ width: `${generation.progress}%` }}
                  />
                </div>
              )}

              {generation.status === 'completed' && (
                <p className="muted">Ready — download in the next step.</p>
              )}

              {generation.status === 'failed' && (
                <div className="generation-card__failed">
                  <p className="field-error">{generation.error_message ?? 'Generation failed'}</p>
                  <button type="button" disabled={busy} onClick={() => void onRetry(generation.id)}>
                    Retry
                  </button>
                </div>
              )}
            </div>
          ))}
        </div>
      )}

      {backLink}
    </section>
  )
}
