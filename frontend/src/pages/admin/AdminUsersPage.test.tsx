import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import type { AdminUser, AdminUserListResponse } from '../../api/admin'
import { AdminUsersPage } from './AdminUsersPage'

const listUsers = vi.fn()
const suspendUser = vi.fn()
const reactivateUser = vi.fn()

vi.mock('../../api/admin', () => ({
  listUsers: (...args: unknown[]) => listUsers(...args),
  suspendUser: (...args: unknown[]) => suspendUser(...args),
  reactivateUser: (...args: unknown[]) => reactivateUser(...args),
}))

function makeUser(overrides: Partial<AdminUser> = {}): AdminUser {
  return {
    id: 1,
    name: 'Ada Lovelace',
    email: 'ada@example.com',
    role: 'user',
    status: 'active',
    email_verified: true,
    projects_count: 2,
    last_login_at: null,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    ...overrides,
  }
}

function response(users: AdminUser[]): AdminUserListResponse {
  return { users, meta: { page: 1, per_page: 20, total_count: users.length, total_pages: 1 } }
}

function renderPage() {
  return render(
    <MemoryRouter>
      <AdminUsersPage />
    </MemoryRouter>,
  )
}

describe('AdminUsersPage', () => {
  beforeEach(() => {
    listUsers.mockReset()
    suspendUser.mockReset()
    reactivateUser.mockReset()
  })

  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('renders a paginated user list with project counts', async () => {
    listUsers.mockResolvedValue(response([makeUser({ name: 'Ada Lovelace' })]))
    renderPage()

    expect(await screen.findByText('ada@example.com')).toBeInTheDocument()
    expect(screen.getByText('Page 1 of 1')).toBeInTheDocument()
  })

  it('suspends a user with a confirmation and reason', async () => {
    listUsers.mockResolvedValue(response([makeUser()]))
    suspendUser.mockResolvedValue(makeUser({ status: 'suspended' }))
    vi.stubGlobal('confirm', vi.fn(() => true))
    vi.stubGlobal('prompt', vi.fn(() => 'spam'))

    renderPage()
    const button = await screen.findByRole('button', { name: 'Suspend' })
    await userEvent.click(button)

    await waitFor(() => expect(suspendUser).toHaveBeenCalledWith(1, 'spam'))
    // The list is refetched after the action.
    expect(listUsers).toHaveBeenCalledTimes(2)
  })

  it('offers reactivate for a suspended user', async () => {
    listUsers.mockResolvedValue(response([makeUser({ status: 'suspended' })]))
    reactivateUser.mockResolvedValue(makeUser({ status: 'active' }))
    renderPage()

    const button = await screen.findByRole('button', { name: 'Reactivate' })
    await userEvent.click(button)
    await waitFor(() => expect(reactivateUser).toHaveBeenCalledWith(1))
  })
})
