/** Human-readable labels for notification email types. */
export const NOTIFICATION_TYPE_LABELS: Record<string, string> = {
  character_ready: 'Character ready for approval',
  character_approved: 'Character approved',
  character_rejected: 'Character rejected',
  approval_link_expired: 'Approval link expired',
  prompt_ready: 'Prompt ready',
  video_generation_started: 'Video generation started',
  video_generation_completed: 'Videos ready',
  video_generation_partially_completed: 'Some videos ready',
  video_generation_failed: 'Video generation failed',
}

export function notificationTypeLabel(emailType: string): string {
  return NOTIFICATION_TYPE_LABELS[emailType] ?? emailType.replace(/_/g, ' ')
}
