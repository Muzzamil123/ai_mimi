import type { VideoStatus } from '../../api/videos'

/**
 * Languages supported for a spoken/typed video idea. Mirrors the backend
 * Project::SUPPORTED_LANGUAGES; the plan explicitly requires these four.
 */
export const VIDEO_LANGUAGE_OPTIONS: { value: string; label: string }[] = [
  { value: 'english', label: 'English' },
  { value: 'urdu', label: 'Urdu' },
  { value: 'roman_urdu', label: 'Roman Urdu' },
  { value: 'punjabi', label: 'Punjabi' },
]

export function formatVideoLanguage(value: string): string {
  return VIDEO_LANGUAGE_OPTIONS.find((option) => option.value === value)?.label ?? value
}

interface StatusMeta {
  label: string
  tone: 'neutral' | 'progress' | 'ok' | 'error' | 'muted'
}

export const VIDEO_STATUS_META: Record<VideoStatus, StatusMeta> = {
  draft: { label: 'Draft', tone: 'neutral' },
  transcribing: { label: 'Transcribing…', tone: 'progress' },
  idea_ready: { label: 'Idea ready', tone: 'ok' },
  generating_prompt: { label: 'Generating prompt…', tone: 'progress' },
  prompt_ready: { label: 'Prompt ready', tone: 'ok' },
  queued: { label: 'Queued', tone: 'progress' },
  generating: { label: 'Generating…', tone: 'progress' },
  partially_completed: { label: 'Partially completed', tone: 'progress' },
  completed: { label: 'Completed', tone: 'ok' },
  failed: { label: 'Failed', tone: 'error' },
  cancelled: { label: 'Cancelled', tone: 'muted' },
}
