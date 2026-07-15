import type { CharacterStatus } from '../api/characters'

interface StatusMeta {
  label: string
  tone: 'neutral' | 'progress' | 'ok' | 'error' | 'muted'
}

const STATUS_META: Record<CharacterStatus, StatusMeta> = {
  pending: { label: 'Not generated', tone: 'neutral' },
  generating: { label: 'Generating…', tone: 'progress' },
  awaiting_approval: { label: 'Awaiting approval', tone: 'progress' },
  rejected: { label: 'Rejected', tone: 'error' },
  approved: { label: 'Approved', tone: 'ok' },
  failed: { label: 'Failed', tone: 'error' },
}

/** Readable, color-coded badge for a character's lifecycle status. */
export function CharacterStatusBadge({ status }: { status: CharacterStatus }) {
  const meta = STATUS_META[status]
  return (
    <span className="status-badge" data-tone={meta.tone}>
      {meta.label}
    </span>
  )
}
