import { useCallback, useEffect, useRef, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import {
  deleteVideo,
  getVideo,
  updateVideo,
  uploadVideoAudio,
  type VideoDetail,
} from '../../api/videos'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { VideoStatusBadge } from '../../components/VideoStatusBadge'
import { getErrorMessage } from '../../lib/errors'
import { AudioRecorder } from './AudioRecorder'
import { formatVideoLanguage } from './options'

const POLL_INTERVAL_MS = 3000

// Statuses in which the idea/transcript can still be edited by the user.
const EDITABLE_STATUSES = new Set(['draft', 'idea_ready', 'failed'])

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; video: VideoDetail }
  | { kind: 'not-found' }
  | { kind: 'error'; message: string }

export function VideoDetailPage() {
  const { id, videoId } = useParams<{ id: string; videoId: string }>()
  const projectId = Number(id)
  const vId = Number(videoId)
  const navigate = useNavigate()

  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [busy, setBusy] = useState(false)
  const [ideaText, setIdeaText] = useState('')
  const [transcript, setTranscript] = useState('')

  const load = useCallback(
    async (options: { silent?: boolean } = {}) => {
      if (!options.silent) setState({ kind: 'loading' })
      try {
        const video = await getVideo(projectId, vId)
        setState({ kind: 'ready', video })
        setIdeaText(video.idea_text ?? '')
        setTranscript(video.transcript ?? '')
      } catch (err) {
        const status = (err as { status?: number }).status
        if (status === 404) {
          setState({ kind: 'not-found' })
          return
        }
        setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load video') })
      }
    },
    [projectId, vId],
  )

  useEffect(() => {
    void load()
  }, [load])

  // Poll while transcription is in flight so the transcript appears automatically.
  const currentStatus = state.kind === 'ready' ? state.video.status : null
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null)
  useEffect(() => {
    if (currentStatus !== 'transcribing') return
    pollRef.current = setInterval(() => void load({ silent: true }), POLL_INTERVAL_MS)
    return () => {
      if (pollRef.current) clearInterval(pollRef.current)
    }
  }, [currentStatus, load])

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

  const onSaveIdea = () =>
    run(async () => {
      await updateVideo(projectId, vId, { idea_text: ideaText })
      toast.success('Idea saved')
    }, 'Unable to save idea')

  const onSaveTranscript = () =>
    run(async () => {
      await updateVideo(projectId, vId, { transcript })
      toast.success('Transcript saved')
    }, 'Unable to save transcript')

  const onAudio = (audio: Blob, filename: string) =>
    run(async () => {
      await uploadVideoAudio(projectId, vId, audio, filename)
      toast.success('Audio uploaded — transcribing…')
    }, 'Unable to upload audio')

  const onDelete = () => {
    if (!window.confirm('Delete this draft video? This cannot be undone.')) return
    void run(async () => {
      await deleteVideo(projectId, vId)
      toast.success('Video deleted')
      navigate(`/projects/${projectId}/videos`, { replace: true })
    }, 'Unable to delete video')
  }

  if (state.kind === 'loading') return <Loading label="Loading video…" />

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
        title="Unable to load video"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  const { video } = state
  const editable = EDITABLE_STATUSES.has(video.status)

  return (
    <section className="video-detail">
      <div className="page-header">
        <div className="page-header__title">
          <h1>{video.title}</h1>
          <VideoStatusBadge status={video.status} />
        </div>
        {video.status === 'draft' && (
          <button type="button" className="danger" disabled={busy} onClick={onDelete}>
            Delete
          </button>
        )}
      </div>

      <dl className="profile-summary">
        <div>
          <dt>Language</dt>
          <dd>{formatVideoLanguage(video.language)}</dd>
        </div>
        <div>
          <dt>Tone</dt>
          <dd>{video.tone || '—'}</dd>
        </div>
        <div>
          <dt>Duration</dt>
          <dd>{video.duration_seconds}s</dd>
        </div>
      </dl>

      {editable && (
        <div className="video-idea">
          <h2>Idea</h2>
          <p className="muted">Type your idea, or record/upload a spoken one below.</p>
          <textarea
            rows={4}
            value={ideaText}
            onChange={(event) => setIdeaText(event.target.value)}
            placeholder="Describe the video idea…"
          />
          <button type="button" disabled={busy} onClick={() => void onSaveIdea()}>
            Save idea
          </button>
        </div>
      )}

      {editable && (
        <div className="video-audio">
          <h2>Speak your idea</h2>
          <AudioRecorder disabled={busy} onRecorded={onAudio} />
        </div>
      )}

      {video.status === 'transcribing' && (
        <div className="generation-progress" role="status">
          <Loading label="Transcribing your spoken idea…" />
        </div>
      )}

      {video.status === 'failed' && (
        <div className="video-failed">
          <p className="field-error">
            Transcription failed: {video.transcription_failure_reason ?? 'unknown error'}
          </p>
          <p className="muted">Record again, or type your idea above.</p>
        </div>
      )}

      {video.has_audio && editable && (
        <div className="video-transcript">
          <h2>Transcript</h2>
          <p className="muted">Edit the transcribed text if the speech-to-text got anything wrong.</p>
          <textarea
            rows={4}
            value={transcript}
            onChange={(event) => setTranscript(event.target.value)}
          />
          <button type="button" disabled={busy} onClick={() => void onSaveTranscript()}>
            Save transcript
          </button>
        </div>
      )}

      <div className="status-history">
        <h2>Status history</h2>
        {video.status_changes.length === 0 ? (
          <p className="muted">No status changes recorded yet.</p>
        ) : (
          <ol className="timeline">
            {video.status_changes.map((change) => (
              <li key={change.id}>
                <span className="timeline__status">
                  {change.from_status ? `${change.from_status} → ` : ''}
                  {change.to_status}
                </span>
                <span className="timeline__meta">
                  {new Date(change.created_at).toLocaleString()}
                  {change.reason ? ` — ${change.reason}` : ''}
                </span>
              </li>
            ))}
          </ol>
        )}
      </div>

      <p className="auth-links">
        <Link to={`/projects/${projectId}/videos`}>Back to videos</Link>
      </p>
    </section>
  )
}
