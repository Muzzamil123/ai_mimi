import type { VideoGenerationStatus } from '../api/videoGenerations'

interface StatusMeta {
  label: string
  tone: 'neutral' | 'progress' | 'ok' | 'error' | 'muted'
}

const STATUS_META: Record<VideoGenerationStatus, StatusMeta> = {
  pending: { label: 'Pending', tone: 'neutral' },
  processing: { label: 'Processing…', tone: 'progress' },
  completed: { label: 'Completed', tone: 'ok' },
  failed: { label: 'Failed', tone: 'error' },
  cancelled: { label: 'Cancelled', tone: 'muted' },
}

/** Readable, color-coded badge for a single output's generation status. */
export function GenerationStatusBadge({ status }: { status: VideoGenerationStatus }) {
  const meta = STATUS_META[status]
  return (
    <span className="status-badge" data-tone={meta.tone}>
      {meta.label}
    </span>
  )
}
