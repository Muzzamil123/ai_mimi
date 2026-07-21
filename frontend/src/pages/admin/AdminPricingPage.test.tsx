import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { ProviderPrice } from '../../api/adminCosts'
import { AdminPricingPage } from './AdminPricingPage'

const listProviderPrices = vi.fn()
const createProviderPrice = vi.fn()
const updateProviderPrice = vi.fn()
const deleteProviderPrice = vi.fn()

vi.mock('../../api/adminCosts', () => ({
  SERVICE_TYPES: ['character_image', 'text_generation', 'speech_to_text', 'video_generation'],
  listProviderPrices: (...a: unknown[]) => listProviderPrices(...a),
  createProviderPrice: (...a: unknown[]) => createProviderPrice(...a),
  updateProviderPrice: (...a: unknown[]) => updateProviderPrice(...a),
  deleteProviderPrice: (...a: unknown[]) => deleteProviderPrice(...a),
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

const PRICE: ProviderPrice = {
  id: 1,
  provider: 'google_labs',
  service_type: 'video_generation',
  model: '',
  currency: 'USD',
  enabled: true,
  per_input_token: null,
  per_output_token: null,
  per_image: null,
  per_second: '0.05',
  per_request: null,
  updated_at: '2026-01-01T00:00:00Z',
}

function renderPage() {
  return render(
    <MemoryRouter>
      <AdminPricingPage />
    </MemoryRouter>,
  )
}

describe('AdminPricingPage', () => {
  beforeEach(() => {
    listProviderPrices.mockReset().mockResolvedValue({ provider_prices: [PRICE] })
    createProviderPrice.mockReset().mockResolvedValue(PRICE)
  })

  it('lists configured prices', async () => {
    renderPage()
    expect(await screen.findByText('google_labs')).toBeInTheDocument()
    expect(screen.getByText(/per_second=0.05/)).toBeInTheDocument()
  })

  it('creates a price', async () => {
    const user = userEvent.setup()
    renderPage()
    await screen.findByText('google_labs')

    await user.type(screen.getByLabelText('Provider'), 'openai')
    await user.click(screen.getByRole('button', { name: 'Add price' }))

    await waitFor(() => expect(createProviderPrice).toHaveBeenCalledTimes(1))
    expect(createProviderPrice.mock.calls[0][0]).toMatchObject({ provider: 'openai' })
  })
})
