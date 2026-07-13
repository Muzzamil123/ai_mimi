import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { ProtectedRoute } from './ProtectedRoute'

interface MockAuth {
  status: 'loading' | 'authenticated' | 'anonymous'
  isAuthenticated: boolean
}

let authValue: MockAuth

vi.mock('../auth/AuthContext', () => ({
  useAuth: () => authValue,
}))

function renderAt(initial = '/profile') {
  return render(
    <MemoryRouter initialEntries={[initial]}>
      <Routes>
        <Route element={<ProtectedRoute />}>
          <Route path="/profile" element={<div>Protected content</div>} />
        </Route>
        <Route path="/login" element={<div>Login page</div>} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('ProtectedRoute', () => {
  beforeEach(() => {
    authValue = { status: 'anonymous', isAuthenticated: false }
  })

  it('redirects an anonymous user to /login', () => {
    authValue = { status: 'anonymous', isAuthenticated: false }
    renderAt()
    expect(screen.getByText('Login page')).toBeInTheDocument()
    expect(screen.queryByText('Protected content')).not.toBeInTheDocument()
  })

  it('renders children when authenticated', () => {
    authValue = { status: 'authenticated', isAuthenticated: true }
    renderAt()
    expect(screen.getByText('Protected content')).toBeInTheDocument()
  })

  it('shows a loading indicator while the session is resolving', () => {
    authValue = { status: 'loading', isAuthenticated: false }
    renderAt()
    expect(screen.getByRole('status')).toBeInTheDocument()
  })
})
