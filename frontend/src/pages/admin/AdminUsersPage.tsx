import { useCallback, useEffect, useState } from 'react'
import { toast } from 'sonner'
import {
  listUsers,
  reactivateUser,
  suspendUser,
  type AdminListMeta,
  type AdminUser,
} from '../../api/admin'
import type { UserRole, UserStatus } from '../../api/auth'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { Pagination } from '../../components/Pagination'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; users: AdminUser[]; meta: AdminListMeta }
  | { kind: 'error'; message: string }

const PER_PAGE = 20

const ROLE_OPTIONS: UserRole[] = ['user', 'admin']
const STATUS_OPTIONS: UserStatus[] = ['active', 'suspended', 'deleted']

export function AdminUsersPage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [searchInput, setSearchInput] = useState('')
  const [query, setQuery] = useState('')
  const [role, setRole] = useState<UserRole | ''>('')
  const [status, setStatus] = useState<UserStatus | ''>('')
  const [page, setPage] = useState(1)
  const [busyId, setBusyId] = useState<number | null>(null)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const { users, meta } = await listUsers({ page, per_page: PER_PAGE, q: query, role, status })
      setState({ kind: 'ready', users, meta })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load users') })
    }
  }, [page, query, role, status])

  useEffect(() => {
    void load()
  }, [load])

  const onSearchSubmit = (event: React.FormEvent) => {
    event.preventDefault()
    setPage(1)
    setQuery(searchInput.trim())
  }

  const onSuspend = async (user: AdminUser) => {
    if (!window.confirm(`Suspend ${user.email}? They will be signed out immediately.`)) return
    const reason = window.prompt('Reason (optional):') ?? undefined
    setBusyId(user.id)
    try {
      await suspendUser(user.id, reason || undefined)
      toast.success(`${user.email} suspended`)
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to suspend user'))
    } finally {
      setBusyId(null)
    }
  }

  const onReactivate = async (user: AdminUser) => {
    setBusyId(user.id)
    try {
      await reactivateUser(user.id)
      toast.success(`${user.email} reactivated`)
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to reactivate user'))
    } finally {
      setBusyId(null)
    }
  }

  return (
    <section className="admin-users">
      <div className="page-header">
        <h1>Users</h1>
      </div>

      <form className="admin-filters" onSubmit={onSearchSubmit}>
        <div className="field">
          <label htmlFor="user-search">Search</label>
          <input
            id="user-search"
            type="search"
            placeholder="Name or email…"
            value={searchInput}
            onChange={(event) => setSearchInput(event.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="user-role">Role</label>
          <select
            id="user-role"
            value={role}
            onChange={(event) => {
              setPage(1)
              setRole(event.target.value as UserRole | '')
            }}
          >
            <option value="">All roles</option>
            {ROLE_OPTIONS.map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        </div>
        <div className="field">
          <label htmlFor="user-status">Status</label>
          <select
            id="user-status"
            value={status}
            onChange={(event) => {
              setPage(1)
              setStatus(event.target.value as UserStatus | '')
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
        <button type="submit">Search</button>
      </form>

      {state.kind === 'loading' && <Loading label="Loading users…" />}

      {state.kind === 'error' && (
        <EmptyState
          title="Unable to load users"
          description={state.message}
          action={
            <button type="button" onClick={() => void load()}>
              Retry
            </button>
          }
        />
      )}

      {state.kind === 'ready' && state.users.length === 0 && (
        <EmptyState title="No users" description="No users match these filters." />
      )}

      {state.kind === 'ready' && state.users.length > 0 && (
        <>
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Name</th>
                  <th>Email</th>
                  <th>Role</th>
                  <th>Status</th>
                  <th>Projects</th>
                  <th>Last login</th>
                  <th>Actions</th>
                </tr>
              </thead>
              <tbody>
                {state.users.map((user) => (
                  <tr key={user.id}>
                    <td>{user.id}</td>
                    <td>{user.name}</td>
                    <td>{user.email}</td>
                    <td>{user.role}</td>
                    <td>
                      <span
                        className="status-badge"
                        data-tone={user.status === 'active' ? 'ok' : 'error'}
                      >
                        {user.status}
                      </span>
                    </td>
                    <td>{user.projects_count}</td>
                    <td>
                      {user.last_login_at
                        ? new Date(user.last_login_at).toLocaleDateString()
                        : '—'}
                    </td>
                    <td>
                      {user.status === 'active' && (
                        <button
                          type="button"
                          className="link-button"
                          disabled={busyId === user.id}
                          onClick={() => void onSuspend(user)}
                        >
                          Suspend
                        </button>
                      )}
                      {user.status === 'suspended' && (
                        <button
                          type="button"
                          className="link-button"
                          disabled={busyId === user.id}
                          onClick={() => void onReactivate(user)}
                        >
                          Reactivate
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
