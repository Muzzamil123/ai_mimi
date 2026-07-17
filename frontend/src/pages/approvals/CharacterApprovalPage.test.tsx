import { render, screen } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { ApprovalRequest } from '../../api/approvals'
import { CharacterApprovalPage } from './CharacterApprovalPage'

const getApproval = vi.fn()
const approveViaToken = vi.fn()
const rejectViaToken = vi.fn()

vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

vi.mock('../../api/approvals', () => ({
  getApproval: (...args: unknown[]) => getApproval(...args),
  approveViaToken: (...args: unknown[]) => approveViaToken(...args),
  rejectViaToken: (...args: unknown[]) => rejectViaToken(...args),
  approvalImageUrl: (token: string) => `http://api.test/approvals/character/${token}/image`,
}))

function request(overrides: Partial<ApprovalRequest> = {}): ApprovalRequest {
  return {
    id: 1,
    status: 'pending',
    actionable: true,
    feedback: null,
    expires_at: '2999-01-01T00:00:00Z',
    responded_at: null,
    project: { name: 'Baby Shark' },
    character: { name: 'Sharky', description: 'A cheerful mascot', has_image: true },
    ...overrides,
  }
}

function renderPage(token = 'tok_123') {
  return render(
    <MemoryRouter initialEntries={[`/approvals/character/${token}`]}>
      <Routes>
        <Route path="/approvals/character/:token" element={<CharacterApprovalPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('CharacterApprovalPage', () => {
  beforeEach(() => {
    getApproval.mockReset()
    approveViaToken.mockReset()
    rejectViaToken.mockReset()
  })

  it('shows approve/reject actions for a pending, actionable link', async () => {
    getApproval.mockResolvedValue(request())
    renderPage()

    expect(await screen.findByRole('button', { name: /approve character/i })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /^reject$/i })).toBeInTheDocument()
    expect(screen.getByRole('img', { name: /sharky/i })).toBeInTheDocument()
  })

  it('approves via the token and reflects the approved state', async () => {
    getApproval.mockResolvedValue(request())
    approveViaToken.mockResolvedValue(request({ status: 'approved', actionable: false }))
    renderPage('tok_abc')

    const user = userEvent.setup()
    await user.click(await screen.findByRole('button', { name: /approve character/i }))

    expect(approveViaToken).toHaveBeenCalledWith('tok_abc')
    expect(await screen.findByText(/character approved/i)).toBeInTheDocument()
  })

  it('collects feedback and rejects via the token', async () => {
    getApproval.mockResolvedValue(request())
    rejectViaToken.mockResolvedValue(request({ status: 'rejected', actionable: false }))
    renderPage('tok_r')

    const user = userEvent.setup()
    await user.click(await screen.findByRole('button', { name: /^reject$/i }))
    await user.type(screen.getByLabelText(/what should change/i), 'make it younger')
    await user.click(screen.getByRole('button', { name: /confirm rejection/i }))

    expect(rejectViaToken).toHaveBeenCalledWith('tok_r', 'make it younger')
    expect(await screen.findByText(/character rejected/i)).toBeInTheDocument()
  })

  it('shows an expired message for an expired link', async () => {
    getApproval.mockResolvedValue(request({ status: 'expired', actionable: false }))
    renderPage()

    expect(await screen.findByText(/approval link expired/i)).toBeInTheDocument()
  })

  it('shows an invalid message when the token is unknown', async () => {
    getApproval.mockRejectedValue({ status: 404, message: 'Invalid approval link' })
    renderPage()

    expect(await screen.findByText(/isn.t valid/i)).toBeInTheDocument()
  })
})
