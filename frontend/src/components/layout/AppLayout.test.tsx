import { render, screen, act } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { describe, expect, it, vi } from 'vitest'
import { AppLayout } from './AppLayout'

vi.mock('../../auth/AuthContext', () => ({
  useAuth: () => ({
    status: 'anonymous',
    isAuthenticated: false,
    isAdmin: false,
    user: null,
    logout: vi.fn(),
  }),
}))

vi.mock('../../api/notifications', () => ({
  listNotifications: vi.fn().mockResolvedValue({ meta: { unread_count: 0 } }),
}))

function renderLayout() {
  return render(
    <MemoryRouter>
      <AppLayout />
    </MemoryRouter>,
  )
}

describe('AppLayout', () => {
  it('renders privacy, terms, and support links in the footer', () => {
    renderLayout()
    expect(screen.getByRole('link', { name: 'Privacy' })).toHaveAttribute('href', '/privacy')
    expect(screen.getByRole('link', { name: 'Terms' })).toHaveAttribute('href', '/terms')
    expect(screen.getByRole('link', { name: 'Support' })).toHaveAttribute(
      'href',
      'mailto:support@aicvp.example',
    )
  })

  it('shows the maintenance banner on app:maintenance and dismisses it', async () => {
    const user = userEvent.setup()
    renderLayout()

    expect(screen.queryByRole('alert')).not.toBeInTheDocument()

    act(() => {
      window.dispatchEvent(new Event('app:maintenance'))
    })

    expect(screen.getByRole('alert')).toHaveTextContent(/maintenance/i)

    await user.click(screen.getByRole('button', { name: /dismiss maintenance notice/i }))
    expect(screen.queryByRole('alert')).not.toBeInTheDocument()
  })
})
