import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { CostReport } from '../../api/adminCosts'
import { AdminCostsPage } from './AdminCostsPage'

const getCosts = vi.fn()
const getUserSpend = vi.fn()
const getProjectSpend = vi.fn()
const exportCosts = vi.fn()

vi.mock('../../api/adminCosts', () => ({
  getCosts: (...a: unknown[]) => getCosts(...a),
  getUserSpend: (...a: unknown[]) => getUserSpend(...a),
  getProjectSpend: (...a: unknown[]) => getProjectSpend(...a),
  exportCosts: (...a: unknown[]) => exportCosts(...a),
}))

const REPORT: CostReport = {
  range: { from: '2026-01-01T00:00:00Z', to: '2026-02-01T00:00:00Z' },
  totals: { estimated_cost: 12.5, count: 8, unpriced_count: 2 },
  by_provider: [
    { key: 'google_labs', estimated_cost: 10, count: 4 },
    { key: 'openai', estimated_cost: 2.5, count: 4 },
  ],
  by_service: [{ key: 'video_generation', estimated_cost: 10, count: 4 }],
  by_day: [{ day: '2026-01-15', estimated_cost: 12.5 }],
  averages: { per_video: 2.5, per_project: 6.25 },
}

function renderPage() {
  return render(
    <MemoryRouter>
      <AdminCostsPage />
    </MemoryRouter>,
  )
}

describe('AdminCostsPage', () => {
  beforeEach(() => {
    getCosts.mockReset().mockResolvedValue(REPORT)
    getUserSpend.mockReset().mockResolvedValue({ rows: [{ id: 1, estimated_cost: 10, count: 4, label: 'a@b.com' }] })
    getProjectSpend.mockReset().mockResolvedValue({ rows: [] })
    exportCosts.mockReset()
  })

  it('renders totals, the unpriced warning, and a provider breakdown', async () => {
    renderPage()

    expect(await screen.findByText('Total spend')).toBeInTheDocument()
    expect(screen.getAllByText('$12.5000').length).toBeGreaterThan(0)
    expect(screen.getByText(/no configured price/i)).toBeInTheDocument()
    expect(screen.getByText('google_labs')).toBeInTheDocument()
    expect(screen.getByText('a@b.com')).toBeInTheDocument()
  })
})
