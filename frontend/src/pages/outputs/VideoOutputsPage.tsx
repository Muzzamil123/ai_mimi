import { useCallback, useEffect, useRef, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import {
  downloadAllOutputs,
  listVideoAssets,
  resolveDownloadUrl,
  type VideoAsset,
} from '../../api/videoAssets'
import { getVideo, type VideoDetail } from '../../api/videos'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

const POLL_INTERVAL_MS = 3000

function formatBytes(bytes: number | null): string {
  if (!bytes) return '—'
  const mb = bytes / (1024 * 1024)
  return mb >= 1 ? `${mb.toFixed(1)} MB` : `${Math.max(1, Math.round(bytes / 1024))} KB`
}

// Still-processing assets (pending, or a generation whose output hasn't landed).
function isProcessing(assets: VideoAsset[], video: VideoDetail): boolean {
  if (video.status === 'queued' || video.status === 'generating') return true
  return assets.some((a) => a.validation_status === 'pending')
}

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; video: VideoDetail; assets: VideoAsset[] }
  | { kind: 'not-found' }
  | { kind: 'error'; message: string }

export function VideoOutputsPage() {
  const { id, videoId } = useParams<{ id: string; videoId: string }>()
  const projectId = Number(id)
  const vId = Number(videoId)

  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [busy, setBusy] = useState(false)

  const load = useCallback(
    async (options: { silent?: boolean } = {}) => {
      if (!options.silent) setState({ kind: 'loading' })
      try {
        const [video, { video_assets }] = await Promise.all([
          getVideo(projectId, vId),
          listVideoAssets(projectId, vId),
        ])
        setState({ kind: 'ready', video, assets: video_assets })
      } catch (err) {
        const status = (err as { status?: number }).status
        if (status === 404) {
          setState({ kind: 'not-found' })
          return
        }
        setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load outputs') })
      }
    },
    [projectId, vId],
  )

  useEffect(() => {
    void load()
  }, [load])

  // Poll while outputs are still processing so they appear automatically.
  const processing = state.kind === 'ready' && isProcessing(state.assets, state.video)
  const pollRef = useRef<ReturnType<typeof setInterval> | null>(null)
  useEffect(() => {
    if (!processing) return
    pollRef.current = setInterval(() => void load({ silent: true }), POLL_INTERVAL_MS)
    return () => {
      if (pollRef.current) clearInterval(pollRef.current)
    }
  }, [processing, load])

  const onDownloadAll = () => {
    setBusy(true)
    void downloadAllOutputs(projectId, vId)
      .catch((err) => toast.error(getErrorMessage(err, 'Unable to download outputs')))
      .finally(() => setBusy(false))
  }

  if (state.kind === 'loading') return <Loading label="Loading outputs…" />

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
        title="Unable to load outputs"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  const { video, assets } = state
  const readyAssets = assets.filter((a) => a.ready)
  const backLink = (
    <p className="auth-links">
      <Link to={`/projects/${projectId}/videos/${vId}/generation`}>Back to generation</Link>
    </p>
  )

  if (assets.length === 0) {
    return (
      <section className="video-outputs">
        <h1>Outputs</h1>
        <EmptyState
          title="No outputs yet"
          description="Generate this video's outputs first; they'll appear here once ready."
          action={<Link to={`/projects/${projectId}/videos/${vId}/generation`}>Go to generation</Link>}
        />
        {backLink}
      </section>
    )
  }

  return (
    <section className="video-outputs">
      <div className="page-header">
        <h1>Outputs — {video.title}</h1>
        <div className="video-header-actions">
          <button type="button" onClick={() => void load({ silent: true })} disabled={busy}>
            Refresh links
          </button>
          {readyAssets.length > 0 && (
            <button type="button" onClick={onDownloadAll} disabled={busy}>
              Download all ({readyAssets.length})
            </button>
          )}
        </div>
      </div>

      <div className="outputs-grid">
        {assets.map((asset) => (
          <div className="output-card" key={asset.id} data-status={asset.validation_status}>
            <div className="output-card__header">
              <span className="output-card__label">
                {asset.aspect_ratio} #{asset.variation_number}
              </span>
              {asset.duplicate && <span className="muted">duplicate</span>}
            </div>

            {asset.ready ? (
              <>
                {asset.stream_url && (
                  <video
                    controls
                    poster={resolveDownloadUrl(asset.thumbnail_url) ?? undefined}
                    src={resolveDownloadUrl(asset.stream_url) ?? undefined}
                    className="output-card__player"
                  />
                )}
                <dl className="output-card__meta">
                  <div>
                    <dt>Size</dt>
                    <dd>
                      {asset.width}×{asset.height} · {asset.duration_seconds}s ·{' '}
                      {formatBytes(asset.file_size)}
                    </dd>
                  </div>
                </dl>
                {asset.download_url && (
                  <a
                    className="button-link"
                    href={resolveDownloadUrl(asset.download_url) ?? '#'}
                    download={asset.filename ?? undefined}
                  >
                    Download
                  </a>
                )}
              </>
            ) : asset.validation_status === 'invalid' || asset.validation_status === 'failed' ? (
              <p className="field-error">
                {asset.validation_status === 'invalid'
                  ? 'This output failed validation.'
                  : 'Processing this output failed.'}
              </p>
            ) : (
              <Loading label="Processing…" />
            )}
          </div>
        ))}
      </div>

      {backLink}
    </section>
  )
}
