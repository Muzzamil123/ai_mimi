import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { BudgetPolicy } from '../../api/adminCosts'
import { AdminBudgetsPage } from './AdminBudgetsPage'

const listBudgetPolicies = vi.fn()
const createBudgetPolicy = vi.fn()
const updateBudgetPolicy = vi.fn()
const deleteBudgetPolicy = vi.fn()

vi.mock('../../api/adminCosts', () => ({
  listBudgetPolicies: (...a: unknown[]) => listBudgetPolicies(...a),
  createBudgetPolicy: (...a: unknown[]) => createBudgetPolicy(...a),
  updateBudgetPolicy: (...a: unknown[]) => updateBudgetPolicy(...a),
  deleteBudgetPolicy: (...a: unknown[]) => deleteBudgetPolicy(...a),
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

const POLICY: BudgetPolicy = {
  id: 1,
  scope_type: 'global',
  scope_id: null,
  provider: null,
  daily_limit: null,
  monthly_limit: 100,
  warning_percentage: 80,
  action_on_limit: 'block',
  enabled: true,
  created_at: '2026-01-01T00:00:00Z',
  updated_at: '2026-01-01T00:00:00Z',
}

function renderPage() {
  return render(
    <MemoryRouter>
      <AdminBudgetsPage />
    </MemoryRouter>,
  )
}

describe('AdminBudgetsPage', () => {
  beforeEach(() => {
    listBudgetPolicies.mockReset().mockResolvedValue({ budget_policies: [POLICY] })
    createBudgetPolicy.mockReset().mockResolvedValue(POLICY)
  })

  it('lists policies with their action badge', async () => {
    renderPage()
    expect(await screen.findByText('$100/mo')).toBeInTheDocument()
    expect(screen.getByText('block', { selector: '.status-badge' })).toBeInTheDocument()
  })

  it('creates a policy', async () => {
    const user = userEvent.setup()
    renderPage()
    await screen.findByText('$100/mo')

    await user.type(screen.getByLabelText('Monthly limit'), '500')
    await user.click(screen.getByRole('button', { name: 'Add policy' }))

    await waitFor(() => expect(createBudgetPolicy).toHaveBeenCalledTimes(1))
    expect(createBudgetPolicy.mock.calls[0][0]).toMatchObject({ scope_type: 'global', monthly_limit: 500 })
  })
})
