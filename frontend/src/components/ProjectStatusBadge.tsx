import type { ProjectStatus } from '../api/projects'

interface StatusMeta {
  label: string
  tone: 'neutral' | 'progress' | 'ok' | 'error' | 'muted'
}

const STATUS_META: Record<ProjectStatus, StatusMeta> = {
  draft: { label: 'Draft', tone: 'neutral' },
  initializing_character: { label: 'Initializing character', tone: 'progress' },
  awaiting_character_approval: { label: 'Awaiting approval', tone: 'progress' },
  character_rejected: { label: 'Character rejected', tone: 'error' },
  ready: { label: 'Ready', tone: 'ok' },
  failed: { label: 'Failed', tone: 'error' },
  archived: { label: 'Archived', tone: 'muted' },
}

/** Readable, color-coded badge for a project's lifecycle status. */
export function ProjectStatusBadge({ status }: { status: ProjectStatus }) {
  const meta = STATUS_META[status]
  return (
    <span className="status-badge" data-tone={meta.tone}>
      {meta.label}
    </span>
  )
}
