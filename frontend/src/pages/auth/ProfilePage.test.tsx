import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { ProfilePage } from './ProfilePage'

const deleteAccount = vi.fn()

vi.mock('../../auth/AuthContext', () => ({
  useAuth: () => ({
    user: { id: 1, name: 'Ada', email: 'ada@example.com', role: 'user', email_verified: true },
    updateProfile: vi.fn(),
    deleteAccount,
  }),
}))

vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

function renderPage() {
  return render(
    <MemoryRouter>
      <ProfilePage />
    </MemoryRouter>,
  )
}

describe('ProfilePage account deletion', () => {
  afterEach(() => {
    deleteAccount.mockReset()
    vi.unstubAllGlobals()
  })

  it('does not delete when the confirmation is cancelled', async () => {
    const confirm = vi.fn().mockReturnValue(false)
    vi.stubGlobal('confirm', confirm)
    const user = userEvent.setup()
    renderPage()

    await user.click(screen.getByRole('button', { name: 'Delete account' }))

    expect(confirm).toHaveBeenCalledOnce()
    expect(deleteAccount).not.toHaveBeenCalled()
  })

  it('deletes when the irreversible-action confirmation is accepted', async () => {
    const confirm = vi.fn().mockReturnValue(true)
    vi.stubGlobal('confirm', confirm)
    deleteAccount.mockResolvedValue(undefined)
    const user = userEvent.setup()
    renderPage()

    await user.click(screen.getByRole('button', { name: 'Delete account' }))

    expect(confirm).toHaveBeenCalledWith(expect.stringMatching(/IRREVERSIBLE/))
    expect(deleteAccount).toHaveBeenCalledOnce()
  })
})
