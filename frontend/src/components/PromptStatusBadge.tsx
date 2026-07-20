import type { PromptStatus } from '../api/prompts'

interface StatusMeta {
  label: string
  tone: 'neutral' | 'progress' | 'ok' | 'error' | 'muted'
}

const STATUS_META: Record<PromptStatus, StatusMeta> = {
  generating: { label: 'Generating…', tone: 'progress' },
  draft: { label: 'Draft', tone: 'neutral' },
  approved: { label: 'Approved', tone: 'ok' },
  failed: { label: 'Failed', tone: 'error' },
  superseded: { label: 'Superseded', tone: 'muted' },
}

/** Readable, color-coded badge for a prompt version's status. */
export function PromptStatusBadge({ status }: { status: PromptStatus }) {
  const meta = STATUS_META[status]
  return (
    <span className="status-badge" data-tone={meta.tone}>
      {meta.label}
    </span>
  )
}
