import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { VideoDetail } from '../../api/videos'
import type { VideoGeneration } from '../../api/videoGenerations'
import { GenerationWorkspacePage } from './GenerationWorkspacePage'

const getVideo = vi.fn()
const listVideoGenerations = vi.fn()
const startVideoGeneration = vi.fn()
const retryVideoGeneration = vi.fn()
const cancelVideoGeneration = vi.fn()

vi.mock('../../api/videos', () => ({
  getVideo: (...args: unknown[]) => getVideo(...args),
}))

vi.mock('../../api/videoGenerations', () => ({
  listVideoGenerations: (...args: unknown[]) => listVideoGenerations(...args),
  startVideoGeneration: (...args: unknown[]) => startVideoGeneration(...args),
  retryVideoGeneration: (...args: unknown[]) => retryVideoGeneration(...args),
  cancelVideoGeneration: (...args: unknown[]) => cancelVideoGeneration(...args),
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

function makeVideo(overrides: Partial<VideoDetail> = {}): VideoDetail {
  return {
    id: 5,
    project_id: 1,
    title: 'Launch teaser',
    idea_text: 'wave',
    transcript: null,
    language: 'english',
    tone: null,
    duration_seconds: 15,
    status: 'prompt_ready',
    active_prompt_id: 9,
    has_audio: false,
    idea_present: true,
    transcription_failure_reason: null,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    status_changes: [],
    ...overrides,
  }
}

function makeGeneration(overrides: Partial<VideoGeneration> = {}): VideoGeneration {
  return {
    id: 100,
    video_id: 5,
    aspect_ratio: '3:4',
    variation_number: 1,
    duration_seconds: 15,
    status: 'processing',
    progress: 50,
    attempt_count: 1,
    error_code: null,
    error_message: null,
    provider: 'fake',
    label: '3:4 #1',
    estimated_cost: 0,
    started_at: null,
    completed_at: null,
    created_at: '2026-01-01T00:00:00Z',
    ...overrides,
  }
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/projects/1/videos/5/generation']}>
      <Routes>
        <Route path="/projects/:id/videos/:videoId/generation" element={<GenerationWorkspacePage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('GenerationWorkspacePage', () => {
  beforeEach(() => {
    getVideo.mockReset()
    listVideoGenerations.mockReset()
    startVideoGeneration.mockReset()
    retryVideoGeneration.mockReset()
    cancelVideoGeneration.mockReset()
  })

  it('prompts to approve a prompt when the video is not ready', async () => {
    getVideo.mockResolvedValue(makeVideo({ status: 'idea_ready', active_prompt_id: null }))
    listVideoGenerations.mockResolvedValue({ video_generations: [] })
    renderPage()

    expect(await screen.findByText('Approve a prompt first')).toBeInTheDocument()
  })

  it('shows the confirmation screen and starts generation', async () => {
    const user = userEvent.setup()
    getVideo.mockResolvedValue(makeVideo())
    listVideoGenerations.mockResolvedValue({ video_generations: [] })
    startVideoGeneration.mockResolvedValue({ video_generations: [] })
    renderPage()

    await user.click(await screen.findByRole('button', { name: 'Start generation' }))

    await waitFor(() => expect(startVideoGeneration).toHaveBeenCalledWith(1, 5))
  })

  it('renders the four output cards with statuses', async () => {
    getVideo.mockResolvedValue(makeVideo({ status: 'partially_completed' }))
    listVideoGenerations.mockResolvedValue({
      video_generations: [
        makeGeneration({ id: 1, label: '3:4 #1', status: 'completed' }),
        makeGeneration({ id: 2, label: '3:4 #2', status: 'completed' }),
        makeGeneration({ id: 3, label: '9:16 #1', status: 'completed' }),
        makeGeneration({ id: 4, label: '9:16 #2', status: 'failed', error_message: 'boom' }),
      ],
    })
    renderPage()

    expect(await screen.findByText('3:4 #1')).toBeInTheDocument()
    expect(screen.getByText('9:16 #2')).toBeInTheDocument()
    expect(screen.getByText('boom')).toBeInTheDocument()
    expect(screen.getByText(/Some outputs failed/)).toBeInTheDocument()
  })

  it('retries a failed output', async () => {
    const user = userEvent.setup()
    getVideo.mockResolvedValue(makeVideo({ status: 'partially_completed' }))
    listVideoGenerations.mockResolvedValue({
      video_generations: [makeGeneration({ id: 7, status: 'failed', error_message: 'boom' })],
    })
    retryVideoGeneration.mockResolvedValue(makeGeneration({ id: 7, status: 'pending' }))
    renderPage()

    await user.click(await screen.findByRole('button', { name: 'Retry' }))

    await waitFor(() => expect(retryVideoGeneration).toHaveBeenCalledWith(1, 5, 7))
  })
})
