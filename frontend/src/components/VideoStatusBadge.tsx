import type { VideoStatus } from '../api/videos'
import { VIDEO_STATUS_META } from '../pages/videos/options'

/** Readable, color-coded badge for a video's lifecycle status. */
export function VideoStatusBadge({ status }: { status: VideoStatus }) {
  const meta = VIDEO_STATUS_META[status]
  return (
    <span className="status-badge" data-tone={meta.tone}>
      {meta.label}
    </span>
  )
}
