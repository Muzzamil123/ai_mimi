import { render, screen, waitFor } from '@testing-library/react'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { HealthPage } from './HealthPage'
import * as healthApi from '../api/health'

vi.mock('sonner', () => ({
  toast: { error: vi.fn(), success: vi.fn() },
}))

describe('HealthPage', () => {
  beforeEach(() => {
    vi.restoreAllMocks()
  })

  it('renders a loading indicator, then health data on success', async () => {
    vi.spyOn(healthApi, 'fetchHealth').mockResolvedValue({
      status: 'ok',
      version: '1.2.3',
      timestamp: '2026-01-01T00:00:00Z',
      components: { database: 'ok', redis: 'ok', sidekiq: 'ok' },
    })

    render(<HealthPage />)

    expect(screen.getByRole('status')).toBeInTheDocument()
    await waitFor(() => expect(screen.getByText('System Health')).toBeInTheDocument())
    expect(screen.getByText('1.2.3')).toBeInTheDocument()
  })

  it('shows an error empty-state when the API is unreachable', async () => {
    vi.spyOn(healthApi, 'fetchHealth').mockRejectedValue(new Error('Network error'))

    render(<HealthPage />)

    await waitFor(() => expect(screen.getByText('API unreachable')).toBeInTheDocument())
    expect(screen.getByText('Network error')).toBeInTheDocument()
  })
})
