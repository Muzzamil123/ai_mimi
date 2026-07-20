import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { VideoDetail } from '../../api/videos'
import type { VideoAsset } from '../../api/videoAssets'
import { VideoOutputsPage } from './VideoOutputsPage'

const getVideo = vi.fn()
const listVideoAssets = vi.fn()
const downloadAllOutputs = vi.fn()

vi.mock('../../api/videos', () => ({
  getVideo: (...args: unknown[]) => getVideo(...args),
}))

vi.mock('../../api/videoAssets', async () => {
  const actual = await vi.importActual<typeof import('../../api/videoAssets')>('../../api/videoAssets')
  return {
    ...actual,
    listVideoAssets: (...args: unknown[]) => listVideoAssets(...args),
    downloadAllOutputs: (...args: unknown[]) => downloadAllOutputs(...args),
  }
})

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
    status: 'completed',
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

function makeAsset(overrides: Partial<VideoAsset> = {}): VideoAsset {
  return {
    id: 1,
    video_generation_id: 1,
    filename: 'output.mp4',
    mime_type: 'video/mp4',
    width: 720,
    height: 960,
    duration_seconds: 15,
    file_size: 2_000_000,
    validation_status: 'valid',
    aspect_ratio: '3:4',
    variation_number: 1,
    ready: true,
    duplicate: false,
    stream_url: '/api/v1/downloads?token=stream',
    download_url: '/api/v1/downloads?token=dl',
    thumbnail_url: '/api/v1/downloads?token=thumb',
    created_at: '2026-01-01T00:00:00Z',
    ...overrides,
  }
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/projects/1/videos/5/outputs']}>
      <Routes>
        <Route path="/projects/:id/videos/:videoId/outputs" element={<VideoOutputsPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('VideoOutputsPage', () => {
  beforeEach(() => {
    getVideo.mockReset()
    listVideoAssets.mockReset()
    downloadAllOutputs.mockReset()
  })

  it('renders ready outputs with a player and download link', async () => {
    getVideo.mockResolvedValue(makeVideo())
    listVideoAssets.mockResolvedValue({ video_assets: [makeAsset()] })
    renderPage()

    expect(await screen.findByText('3:4 #1')).toBeInTheDocument()
    expect(screen.getByText('720×960 · 15s · 1.9 MB')).toBeInTheDocument()
    const link = screen.getByRole('link', { name: 'Download' })
    expect(link).toHaveAttribute('href', 'http://localhost:3000/api/v1/downloads?token=dl')
  })

  it('shows a failed-processing message', async () => {
    getVideo.mockResolvedValue(makeVideo({ status: 'partially_completed' }))
    listVideoAssets.mockResolvedValue({
      video_assets: [makeAsset({ id: 2, ready: false, validation_status: 'failed' })],
    })
    renderPage()

    expect(await screen.findByText('Processing this output failed.')).toBeInTheDocument()
  })

  it('downloads all outputs', async () => {
    const user = userEvent.setup()
    getVideo.mockResolvedValue(makeVideo())
    listVideoAssets.mockResolvedValue({ video_assets: [makeAsset()] })
    downloadAllOutputs.mockResolvedValue(undefined)
    renderPage()

    await user.click(await screen.findByRole('button', { name: /Download all/ }))

    await waitFor(() => expect(downloadAllOutputs).toHaveBeenCalledWith(1, 5))
  })

  it('shows the empty state when there are no outputs', async () => {
    getVideo.mockResolvedValue(makeVideo({ status: 'prompt_ready' }))
    listVideoAssets.mockResolvedValue({ video_assets: [] })
    renderPage()

    expect(await screen.findByText('No outputs yet')).toBeInTheDocument()
  })
})
