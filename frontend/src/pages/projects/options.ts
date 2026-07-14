import type { ProjectLanguage, ProjectPlatform, ProjectStatus } from '../../api/projects'

export const LANGUAGE_OPTIONS: { value: ProjectLanguage; label: string }[] = [
  { value: 'english', label: 'English' },
  { value: 'urdu', label: 'Urdu' },
  { value: 'roman_urdu', label: 'Roman Urdu' },
  { value: 'punjabi', label: 'Punjabi' },
]

export const PLATFORM_OPTIONS: { value: ProjectPlatform; label: string }[] = [
  { value: 'instagram_reels', label: 'Instagram Reels' },
  { value: 'tiktok', label: 'TikTok' },
  { value: 'youtube_shorts', label: 'YouTube Shorts' },
  { value: 'other', label: 'Other' },
]

export const STATUS_FILTER_OPTIONS: { value: ProjectStatus; label: string }[] = [
  { value: 'draft', label: 'Draft' },
  { value: 'initializing_character', label: 'Initializing character' },
  { value: 'awaiting_character_approval', label: 'Awaiting approval' },
  { value: 'character_rejected', label: 'Character rejected' },
  { value: 'ready', label: 'Ready' },
  { value: 'failed', label: 'Failed' },
  { value: 'archived', label: 'Archived' },
]

export function formatLanguage(value: string): string {
  return LANGUAGE_OPTIONS.find((option) => option.value === value)?.label ?? value
}

export function formatPlatform(value: string): string {
  return PLATFORM_OPTIONS.find((option) => option.value === value)?.label ?? value
}
