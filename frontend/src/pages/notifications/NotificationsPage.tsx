import { useCallback, useEffect, useState } from 'react'
import { toast } from 'sonner'
import {
  getNotificationPreferences,
  listNotifications,
  markNotificationsRead,
  retryNotification,
  updateNotificationPreferences,
  type Notification,
  type NotificationPreferences,
} from '../../api/notifications'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'
import { notificationTypeLabel } from './labels'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; notifications: Notification[]; unread: number }
  | { kind: 'error'; message: string }

export function NotificationsPage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [prefs, setPrefs] = useState<NotificationPreferences | null>(null)
  const [busy, setBusy] = useState(false)

  const load = useCallback(async () => {
    try {
      const [{ notifications, meta }, preferences] = await Promise.all([
        listNotifications(),
        getNotificationPreferences(),
      ])
      setState({ kind: 'ready', notifications, unread: meta.unread_count })
      setPrefs(preferences)
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load notifications') })
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const onMarkAllRead = async () => {
    setBusy(true)
    try {
      await markNotificationsRead()
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to mark as read'))
    } finally {
      setBusy(false)
    }
  }

  const onRetry = async (id: number) => {
    setBusy(true)
    try {
      await retryNotification(id)
      toast.success('Retrying delivery…')
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to retry'))
    } finally {
      setBusy(false)
    }
  }

  const onTogglePref = async (type: string, enabled: boolean) => {
    try {
      const updated = await updateNotificationPreferences({ [type]: enabled })
      setPrefs(updated)
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to update preferences'))
    }
  }

  if (state.kind === 'loading') return <Loading label="Loading notifications…" />

  if (state.kind === 'error') {
    return (
      <EmptyState
        title="Unable to load notifications"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  return (
    <section className="notifications-page">
      <div className="page-header">
        <h1>Notifications {state.unread > 0 && <span className="badge">{state.unread}</span>}</h1>
        {state.unread > 0 && (
          <button type="button" disabled={busy} onClick={() => void onMarkAllRead()}>
            Mark all read
          </button>
        )}
      </div>

      {state.notifications.length === 0 ? (
        <EmptyState title="No notifications yet" description="Workflow updates will appear here." />
      ) : (
        <ul className="notification-list">
          {state.notifications.map((n) => (
            <li key={n.id} className="notification" data-unread={!n.read} data-status={n.status}>
              <div className="notification__body">
                <span className="notification__type">{notificationTypeLabel(n.email_type)}</span>
                {n.subject && <span className="notification__subject">{n.subject}</span>}
                <span className="notification__meta">
                  {new Date(n.created_at).toLocaleString()} · {n.status}
                </span>
              </div>
              {n.status === 'failed' && (
                <button type="button" disabled={busy} onClick={() => void onRetry(n.id)}>
                  Retry
                </button>
              )}
            </li>
          ))}
        </ul>
      )}

      {prefs && (
        <div className="notification-preferences">
          <h2>Email preferences</h2>
          <p className="muted">Turn optional emails on or off. Approval and result emails are always sent.</p>
          {prefs.optional_email_types.map((type) => (
            <label key={type} className="pref-toggle">
              <input
                type="checkbox"
                checked={prefs.preferences[type] ?? true}
                onChange={(event) => void onTogglePref(type, event.target.checked)}
              />
              {notificationTypeLabel(type)}
            </label>
          ))}
        </div>
      )}
    </section>
  )
}
