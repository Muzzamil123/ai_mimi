import { apiClient } from './client'

export type NotificationStatus = 'queued' | 'sent' | 'delivered' | 'failed' | 'bounced'

export interface Notification {
  id: number
  email_type: string
  subject: string | null
  status: NotificationStatus
  project_id: number | null
  video_id: number | null
  read: boolean
  created_at: string
}

export interface NotificationListMeta {
  page: number
  per_page: number
  total_count: number
  total_pages: number
  unread_count: number
}

export interface NotificationListResponse {
  notifications: Notification[]
  meta: NotificationListMeta
}

export interface NotificationPreferences {
  optional_email_types: string[]
  preferences: Record<string, boolean>
}

export async function listNotifications(
  params: { page?: number; unread?: boolean } = {},
): Promise<NotificationListResponse> {
  const query: Record<string, string | number> = {}
  if (params.page) query.page = params.page
  if (params.unread) query.unread = 'true'
  const { data } = await apiClient.get<NotificationListResponse>('/notifications', { params: query })
  return data
}

export async function markNotificationsRead(ids?: number[]): Promise<{ unread_count: number }> {
  const { data } = await apiClient.post<{ unread_count: number }>('/notifications/read', { ids })
  return data
}

export async function retryNotification(id: number): Promise<void> {
  await apiClient.post(`/notifications/${id}/retry`)
}

export async function getNotificationPreferences(): Promise<NotificationPreferences> {
  const { data } = await apiClient.get<NotificationPreferences>('/me/notification_preferences')
  return data
}

export async function updateNotificationPreferences(
  preferences: Record<string, boolean>,
): Promise<NotificationPreferences> {
  const { data } = await apiClient.patch<NotificationPreferences>('/me/notification_preferences', {
    preferences,
  })
  return data
}
