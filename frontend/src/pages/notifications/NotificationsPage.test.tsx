import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { Notification, NotificationPreferences } from '../../api/notifications'
import { NotificationsPage } from './NotificationsPage'

const listNotifications = vi.fn()
const markNotificationsRead = vi.fn()
const retryNotification = vi.fn()
const getNotificationPreferences = vi.fn()
const updateNotificationPreferences = vi.fn()

vi.mock('../../api/notifications', () => ({
  listNotifications: (...a: unknown[]) => listNotifications(...a),
  markNotificationsRead: (...a: unknown[]) => markNotificationsRead(...a),
  retryNotification: (...a: unknown[]) => retryNotification(...a),
  getNotificationPreferences: (...a: unknown[]) => getNotificationPreferences(...a),
  updateNotificationPreferences: (...a: unknown[]) => updateNotificationPreferences(...a),
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

function makeNotification(overrides: Partial<Notification> = {}): Notification {
  return {
    id: 1,
    email_type: 'video_generation_completed',
    subject: 'Your videos are ready',
    status: 'sent',
    project_id: 1,
    video_id: 2,
    read: false,
    created_at: '2026-01-01T00:00:00Z',
    ...overrides,
  }
}

const prefs: NotificationPreferences = {
  optional_email_types: ['prompt_ready'],
  preferences: { prompt_ready: true },
}

function renderPage() {
  return render(
    <MemoryRouter>
      <NotificationsPage />
    </MemoryRouter>,
  )
}

describe('NotificationsPage', () => {
  beforeEach(() => {
    listNotifications.mockReset()
    markNotificationsRead.mockReset()
    retryNotification.mockReset()
    getNotificationPreferences.mockReset()
    updateNotificationPreferences.mockReset()
    getNotificationPreferences.mockResolvedValue(prefs)
  })

  it('renders the feed with an unread count and a preferences toggle', async () => {
    listNotifications.mockResolvedValue({
      notifications: [makeNotification()],
      meta: { page: 1, per_page: 20, total_count: 1, total_pages: 1, unread_count: 1 },
    })
    renderPage()

    expect(await screen.findByText('Videos ready')).toBeInTheDocument()
    expect(screen.getByRole('checkbox')).toBeChecked()
  })

  it('retries a failed notification', async () => {
    const user = userEvent.setup()
    listNotifications.mockResolvedValue({
      notifications: [makeNotification({ id: 9, status: 'failed' })],
      meta: { page: 1, per_page: 20, total_count: 1, total_pages: 1, unread_count: 0 },
    })
    retryNotification.mockResolvedValue(undefined)
    renderPage()

    await user.click(await screen.findByRole('button', { name: 'Retry' }))

    await waitFor(() => expect(retryNotification).toHaveBeenCalledWith(9))
  })

  it('marks all read', async () => {
    const user = userEvent.setup()
    listNotifications.mockResolvedValue({
      notifications: [makeNotification()],
      meta: { page: 1, per_page: 20, total_count: 1, total_pages: 1, unread_count: 1 },
    })
    markNotificationsRead.mockResolvedValue({ unread_count: 0 })
    renderPage()

    await user.click(await screen.findByRole('button', { name: 'Mark all read' }))

    await waitFor(() => expect(markNotificationsRead).toHaveBeenCalled())
  })
})
