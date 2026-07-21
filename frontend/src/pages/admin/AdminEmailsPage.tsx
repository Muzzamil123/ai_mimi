import { useCallback, useEffect, useState } from 'react'
import { toast } from 'sonner'
import {
  listEmailDeliveries,
  retryEmailDelivery,
  type AdminEmailDelivery,
  type AdminListMeta,
  type EmailDeliveryStatus,
} from '../../api/admin'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { Pagination } from '../../components/Pagination'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; deliveries: AdminEmailDelivery[]; meta: AdminListMeta }
  | { kind: 'error'; message: string }

const PER_PAGE = 20

const STATUS_OPTIONS: EmailDeliveryStatus[] = ['queued', 'sent', 'delivered', 'failed', 'bounced']
const RETRYABLE: EmailDeliveryStatus[] = ['failed', 'bounced']

function toneFor(status: EmailDeliveryStatus): 'ok' | 'error' | 'progress' | 'neutral' {
  if (status === 'delivered' || status === 'sent') return 'ok'
  if (status === 'failed' || status === 'bounced') return 'error'
  if (status === 'queued') return 'progress'
  return 'neutral'
}

export function AdminEmailsPage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [status, setStatus] = useState<EmailDeliveryStatus | ''>('')
  const [page, setPage] = useState(1)
  const [busyId, setBusyId] = useState<number | null>(null)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const { email_deliveries, meta } = await listEmailDeliveries({
        page,
        per_page: PER_PAGE,
        status,
      })
      setState({ kind: 'ready', deliveries: email_deliveries, meta })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load email deliveries') })
    }
  }, [page, status])

  useEffect(() => {
    void load()
  }, [load])

  const onRetry = async (delivery: AdminEmailDelivery) => {
    setBusyId(delivery.id)
    try {
      await retryEmailDelivery(delivery.id)
      toast.success('Delivery re-queued')
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to retry delivery'))
    } finally {
      setBusyId(null)
    }
  }

  return (
    <section className="admin-emails">
      <div className="page-header">
        <h1>Email deliveries</h1>
      </div>

      <form className="admin-filters" onSubmit={(event) => event.preventDefault()}>
        <div className="field">
          <label htmlFor="email-status">Status</label>
          <select
            id="email-status"
            value={status}
            onChange={(event) => {
              setPage(1)
              setStatus(event.target.value as EmailDeliveryStatus | '')
            }}
          >
            <option value="">All statuses</option>
            {STATUS_OPTIONS.map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        </div>
      </form>

      {state.kind === 'loading' && <Loading label="Loading deliveries…" />}

      {state.kind === 'error' && (
        <EmptyState
          title="Unable to load deliveries"
          description={state.message}
          action={
            <button type="button" onClick={() => void load()}>
              Retry
            </button>
          }
        />
      )}

      {state.kind === 'ready' && state.deliveries.length === 0 && (
        <EmptyState title="No deliveries" description="No email deliveries match these filters." />
      )}

      {state.kind === 'ready' && state.deliveries.length > 0 && (
        <>
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Type</th>
                  <th>Recipient</th>
                  <th>Status</th>
                  <th>Error</th>
                  <th>Sent</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {state.deliveries.map((delivery) => (
                  <tr key={delivery.id}>
                    <td>{delivery.id}</td>
                    <td>{delivery.email_type}</td>
                    <td>{delivery.recipient}</td>
                    <td>
                      <span className="status-badge" data-tone={toneFor(delivery.status)}>
                        {delivery.status}
                      </span>
                    </td>
                    <td className="admin-muted">{delivery.error_message ?? '—'}</td>
                    <td>
                      {delivery.sent_at ? new Date(delivery.sent_at).toLocaleString() : '—'}
                    </td>
                    <td>
                      {RETRYABLE.includes(delivery.status) && (
                        <button
                          type="button"
                          className="link-button"
                          disabled={busyId === delivery.id}
                          onClick={() => void onRetry(delivery)}
                        >
                          Retry
                        </button>
                      )}
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <Pagination meta={state.meta} onPageChange={setPage} />
        </>
      )}
    </section>
  )
}
