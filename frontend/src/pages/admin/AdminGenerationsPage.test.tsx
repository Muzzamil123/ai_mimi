import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { AdminGenerationListResponse } from '../../api/admin'
import type { VideoGeneration } from '../../api/videoGenerations'
import { AdminGenerationsPage } from './AdminGenerationsPage'

const listGenerations = vi.fn()
const retryGeneration = vi.fn()
const retryGenerationAsset = vi.fn()
const cancelGeneration = vi.fn()

vi.mock('../../api/admin', () => ({
  listGenerations: (...args: unknown[]) => listGenerations(...args),
  retryGeneration: (...args: unknown[]) => retryGeneration(...args),
  retryGenerationAsset: (...args: unknown[]) => retryGenerationAsset(...args),
  cancelGeneration: (...args: unknown[]) => cancelGeneration(...args),
}))

function makeGeneration(overrides: Partial<VideoGeneration> = {}): VideoGeneration {
  return {
    id: 10,
    video_id: 3,
    aspect_ratio: '3:4',
    variation_number: 1,
    duration_seconds: 15,
    status: 'failed',
    progress: 0,
    attempt_count: 1,
    error_code: 'provider_error',
    error_message: 'boom',
    provider: 'fake',
    label: '3:4 #1',
    estimated_cost: null,
    started_at: null,
    completed_at: null,
    created_at: '2026-01-01T00:00:00Z',
    ...overrides,
  }
}

function response(generations: VideoGeneration[]): AdminGenerationListResponse {
  return {
    generations,
    meta: { page: 1, per_page: 20, total_count: generations.length, total_pages: 1 },
  }
}

describe('AdminGenerationsPage', () => {
  beforeEach(() => {
    listGenerations.mockReset()
    retryGeneration.mockReset()
  })

  it('retries a failed variant', async () => {
    listGenerations.mockResolvedValue(response([makeGeneration()]))
    retryGeneration.mockResolvedValue(makeGeneration({ status: 'pending' }))

    render(
      <MemoryRouter>
        <AdminGenerationsPage />
      </MemoryRouter>,
    )

    const button = await screen.findByRole('button', { name: 'Retry' })
    await userEvent.click(button)
    await waitFor(() => expect(retryGeneration).toHaveBeenCalledWith(10))
  })
})
