import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { VideoDetail } from '../../api/videos'
import { VideoDetailPage } from './VideoDetailPage'

const getVideo = vi.fn()
const updateVideo = vi.fn()
const deleteVideo = vi.fn()
const uploadVideoAudio = vi.fn()

vi.mock('../../api/videos', () => ({
  getVideo: (...args: unknown[]) => getVideo(...args),
  updateVideo: (...args: unknown[]) => updateVideo(...args),
  deleteVideo: (...args: unknown[]) => deleteVideo(...args),
  uploadVideoAudio: (...args: unknown[]) => uploadVideoAudio(...args),
}))

// The recorder is exercised separately; stub it so this suite focuses on the page.
vi.mock('./AudioRecorder', () => ({
  AudioRecorder: () => <div data-testid="audio-recorder" />,
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

function makeVideo(overrides: Partial<VideoDetail> = {}): VideoDetail {
  return {
    id: 5,
    project_id: 1,
    title: 'Launch teaser',
    idea_text: null,
    transcript: null,
    language: 'english',
    tone: null,
    duration_seconds: 15,
    status: 'draft',
    active_prompt_id: null,
    has_audio: false,
    idea_present: false,
    transcription_failure_reason: null,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    status_changes: [],
    ...overrides,
  }
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/projects/1/videos/5']}>
      <Routes>
        <Route path="/projects/:id/videos/:videoId" element={<VideoDetailPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('VideoDetailPage', () => {
  beforeEach(() => {
    getVideo.mockReset()
    updateVideo.mockReset()
    deleteVideo.mockReset()
    uploadVideoAudio.mockReset()
  })

  it('renders the video with an editable idea box for a draft', async () => {
    getVideo.mockResolvedValue(makeVideo())
    renderPage()

    expect(await screen.findByRole('heading', { name: 'Launch teaser' })).toBeInTheDocument()
    expect(screen.getByPlaceholderText('Describe the video idea…')).toBeInTheDocument()
    expect(screen.getByTestId('audio-recorder')).toBeInTheDocument()
  })

  it('saves a typed idea', async () => {
    const user = userEvent.setup()
    getVideo.mockResolvedValue(makeVideo())
    updateVideo.mockResolvedValue(makeVideo({ idea_text: 'A fun clip', status: 'idea_ready' }))
    renderPage()

    const box = await screen.findByPlaceholderText('Describe the video idea…')
    await user.type(box, 'A fun clip')
    await user.click(screen.getByRole('button', { name: 'Save idea' }))

    await waitFor(() =>
      expect(updateVideo).toHaveBeenCalledWith(1, 5, { idea_text: 'A fun clip' }),
    )
  })

  it('shows a transcript editor once audio has been transcribed', async () => {
    getVideo.mockResolvedValue(
      makeVideo({ status: 'idea_ready', has_audio: true, transcript: 'spoken idea' }),
    )
    renderPage()

    expect(await screen.findByRole('heading', { name: 'Transcript' })).toBeInTheDocument()
    expect(screen.getByDisplayValue('spoken idea')).toBeInTheDocument()
  })

  it('surfaces a transcription failure', async () => {
    getVideo.mockResolvedValue(
      makeVideo({ status: 'failed', transcription_failure_reason: 'bad audio' }),
    )
    renderPage()

    expect(await screen.findByText(/Transcription failed: bad audio/)).toBeInTheDocument()
  })
})
