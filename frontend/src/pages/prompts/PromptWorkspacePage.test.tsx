import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { Prompt } from '../../api/prompts'
import type { VideoDetail } from '../../api/videos'
import { PromptWorkspacePage } from './PromptWorkspacePage'

const getVideo = vi.fn()
const listPrompts = vi.fn()
const generatePrompt = vi.fn()
const savePromptVersion = vi.fn()
const approvePrompt = vi.fn()

vi.mock('../../api/videos', () => ({
  getVideo: (...args: unknown[]) => getVideo(...args),
}))

vi.mock('../../api/prompts', () => ({
  listPrompts: (...args: unknown[]) => listPrompts(...args),
  generatePrompt: (...args: unknown[]) => generatePrompt(...args),
  savePromptVersion: (...args: unknown[]) => savePromptVersion(...args),
  approvePrompt: (...args: unknown[]) => approvePrompt(...args),
}))

vi.mock('sonner', () => ({ toast: { success: vi.fn(), error: vi.fn() } }))

function makeVideo(overrides: Partial<VideoDetail> = {}): VideoDetail {
  return {
    id: 5,
    project_id: 1,
    title: 'Launch teaser',
    idea_text: 'wave hello',
    transcript: null,
    language: 'english',
    tone: null,
    duration_seconds: 15,
    status: 'idea_ready',
    active_prompt_id: null,
    has_audio: false,
    idea_present: true,
    transcription_failure_reason: null,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    status_changes: [],
    ...overrides,
  }
}

function makePrompt(overrides: Partial<Prompt> = {}): Prompt {
  return {
    id: 10,
    video_id: 5,
    version: 1,
    content: 'A 15-second clip of the mascot waving.',
    source_idea: 'wave hello',
    provider: 'openai',
    provider_model: 'gpt-4o-mini',
    status: 'draft',
    input_tokens: 120,
    output_tokens: 200,
    estimated_cost: 0.0003,
    created_by_type: 'User',
    created_by_id: 1,
    failure_reason: null,
    active: false,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    ...overrides,
  }
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/projects/1/videos/5/prompt']}>
      <Routes>
        <Route path="/projects/:id/videos/:videoId/prompt" element={<PromptWorkspacePage />} />
      </Routes>
    </MemoryRouter>,
  )
}

describe('PromptWorkspacePage', () => {
  beforeEach(() => {
    getVideo.mockReset()
    listPrompts.mockReset()
    generatePrompt.mockReset()
    savePromptVersion.mockReset()
    approvePrompt.mockReset()
  })

  it('prompts to add an idea when the video has none', async () => {
    getVideo.mockResolvedValue(makeVideo({ idea_present: false }))
    listPrompts.mockResolvedValue({ prompts: [], meta: {} })
    renderPage()

    expect(await screen.findByText('Add an idea first')).toBeInTheDocument()
  })

  it('offers to generate when no prompt exists yet', async () => {
    getVideo.mockResolvedValue(makeVideo())
    listPrompts.mockResolvedValue({ prompts: [], meta: {} })
    renderPage()

    expect(await screen.findByRole('button', { name: 'Generate prompt' })).toBeInTheDocument()
  })

  it('starts generation on click', async () => {
    const user = userEvent.setup()
    getVideo.mockResolvedValue(makeVideo())
    listPrompts.mockResolvedValue({ prompts: [], meta: {} })
    generatePrompt.mockResolvedValue(makePrompt({ status: 'generating', content: null }))
    renderPage()

    await user.click(await screen.findByRole('button', { name: 'Generate prompt' }))

    await waitFor(() => expect(generatePrompt).toHaveBeenCalledWith(1, 5))
  })

  it('shows the editor and approves a draft', async () => {
    const user = userEvent.setup()
    getVideo.mockResolvedValue(makeVideo({ status: 'prompt_ready' }))
    listPrompts.mockResolvedValue({ prompts: [makePrompt()], meta: {} })
    approvePrompt.mockResolvedValue(makePrompt({ status: 'approved', active: true }))
    renderPage()

    expect(await screen.findByDisplayValue('A 15-second clip of the mascot waving.')).toBeInTheDocument()
    await user.click(screen.getByRole('button', { name: 'Approve' }))

    await waitFor(() => expect(approvePrompt).toHaveBeenCalledWith(1, 5, 10))
  })

  it('renders version history', async () => {
    getVideo.mockResolvedValue(makeVideo({ status: 'prompt_ready' }))
    listPrompts.mockResolvedValue({
      prompts: [makePrompt({ id: 11, version: 2 }), makePrompt({ id: 10, version: 1, status: 'superseded' })],
      meta: {},
    })
    renderPage()

    expect(await screen.findByText('Version history')).toBeInTheDocument()
    expect(screen.getByText('Superseded')).toBeInTheDocument()
  })
})
