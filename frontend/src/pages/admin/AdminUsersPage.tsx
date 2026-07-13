import { useCallback, useEffect, useState } from 'react'
import { listUsers, type AuthUser } from '../../api/auth'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  { kind: 'loading' } | { kind: 'ready'; users: AuthUser[] } | { kind: 'error'; message: string }

export function AdminUsersPage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const users = await listUsers()
      setState({ kind: 'ready', users })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load users') })
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  if (state.kind === 'loading') {
    return <Loading label="Loading users…" />
  }

  if (state.kind === 'error') {
    return (
      <EmptyState
        title="Unable to load users"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  if (state.users.length === 0) {
    return <EmptyState title="No users" description="There are no users to display." />
  }

  return (
    <section className="admin-users">
      <h1>Users</h1>
      <div className="table-scroll">
        <table className="data-table">
          <thead>
            <tr>
              <th>ID</th>
              <th>Name</th>
              <th>Email</th>
              <th>Role</th>
              <th>Status</th>
              <th>Verified</th>
            </tr>
          </thead>
          <tbody>
            {state.users.map((user) => (
              <tr key={user.id}>
                <td>{user.id}</td>
                <td>{user.name}</td>
                <td>{user.email}</td>
                <td>{user.role}</td>
                <td>{user.status}</td>
                <td>{user.email_verified ? 'Yes' : 'No'}</td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
    </section>
  )
}
