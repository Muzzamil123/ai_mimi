import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { ProjectDetail } from '../../api/projects'
import type { Video, VideoListResponse } from '../../api/videos'
import { VideosListPage } from './VideosListPage'

const getProject = vi.fn()
const listVideos = vi.fn()

vi.mock('../../api/projects', () => ({
  getProject: (...args: unknown[]) => getProject(...args),
}))

vi.mock('../../api/videos', () => ({
  listVideos: (...args: unknown[]) => listVideos(...args),
}))

function makeProject(overrides: Partial<ProjectDetail> = {}): ProjectDetail {
  return {
    id: 1,
    user_id: 1,
    name: 'My project',
    slug: 'my-project',
    description: null,
    default_language: 'english',
    default_tone: '',
    target_platforms: [],
    status: 'ready',
    active_character_id: 1,
    archived_at: null,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    status_changes: [],
    ...overrides,
  }
}

function makeVideo(overrides: Partial<Video> = {}): Video {
  return {
    id: 1,
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
    ...overrides,
  }
}

function response(videos: Video[]): VideoListResponse {
  return { videos, meta: { page: 1, per_page: 10, total_count: videos.length, total_pages: 1 } }
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/projects/1/videos']}>
      <Routes>
        <Route path="/projects/:id/videos" element={<VideosListPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('VideosListPage', () => {
  beforeEach(() => {
    getProject.mockReset()
    listVideos.mockReset()
  })

  it('lists the project videos when ready', async () => {
    getProject.mockResolvedValue(makeProject())
    listVideos.mockResolvedValue(response([makeVideo({ title: 'Launch teaser' })]))
    renderPage()

    expect(await screen.findByRole('link', { name: 'Launch teaser' })).toBeInTheDocument()
  })

  it('prompts for character approval when the project is not ready', async () => {
    getProject.mockResolvedValue(makeProject({ status: 'draft' }))
    renderPage()

    expect(await screen.findByText('Character approval required')).toBeInTheDocument()
    expect(listVideos).not.toHaveBeenCalled()
  })

  it('shows the empty state when there are no videos', async () => {
    getProject.mockResolvedValue(makeProject())
    listVideos.mockResolvedValue(response([]))
    renderPage()

    expect(await screen.findByText('No videos yet')).toBeInTheDocument()
  })
})
