import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { Character } from '../../api/characters'
import { CharacterPage } from './CharacterPage'

const getCharacter = vi.fn()
let isAdmin = false

vi.mock('sonner', () => ({ toast: { error: vi.fn(), success: vi.fn() } }))

vi.mock('../../api/characters', () => ({
  getCharacter: (...args: unknown[]) => getCharacter(...args),
  createCharacter: vi.fn(),
  updateCharacter: vi.fn(),
  deleteCharacter: vi.fn(),
  generateCharacter: vi.fn(),
  approveCharacter: vi.fn(),
  rejectCharacter: vi.fn(),
  resetCharacter: vi.fn(),
}))

vi.mock('../../auth/AuthContext', () => ({ useAuth: () => ({ isAdmin }) }))

// Isolate the page from the authed image-fetch flow.
vi.mock('./CharacterPreview', () => ({
  CharacterPreview: () => <div data-testid="preview" />,
}))

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/projects/1/character']}>
      <Routes>
        <Route path="/projects/:id/character" element={<CharacterPage />} />
      </Routes>
    </MemoryRouter>,
  )
}

function character(overrides: Partial<Character>): Character {
  return {
    id: 1,
    project_id: 1,
    name: 'Rusty',
    description: null,
    attributes: {},
    style_preferences: {},
    status: 'pending',
    provider: null,
    provider_model: null,
    generation_prompt: null,
    failure_reason: null,
    rejection_feedback: null,
    locked: false,
    estimated_cost: null,
    image_url: null,
    latest_image: null,
    approved_at: null,
    rejected_at: null,
    locked_at: null,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    ...overrides,
  }
}

describe('CharacterPage', () => {
  beforeEach(() => {
    getCharacter.mockReset()
    isAdmin = false
  })

  it('shows the setup form when no character exists yet (404)', async () => {
    getCharacter.mockRejectedValue({ status: 404 })
    renderPage()

    expect(await screen.findByRole('heading', { name: 'Set up your character' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: 'Save character' })).toBeInTheDocument()
  })

  it('offers approve and reject actions while awaiting approval', async () => {
    getCharacter.mockResolvedValue(character({ status: 'awaiting_approval', image_url: '/x' }))
    renderPage()

    expect(await screen.findByRole('button', { name: 'Approve character' })).toBeInTheDocument()
    expect(screen.getByRole('button', { name: /Reject/ })).toBeInTheDocument()
  })

  it('shows the locked approval status and hides admin reset for non-admins', async () => {
    getCharacter.mockResolvedValue(character({ status: 'approved', locked: true, image_url: '/x' }))
    renderPage()

    expect(await screen.findByText(/Approved and locked/)).toBeInTheDocument()
    expect(screen.queryByRole('button', { name: /Reset character/ })).not.toBeInTheDocument()
  })

  it('shows the admin reset action for admins', async () => {
    isAdmin = true
    getCharacter.mockResolvedValue(character({ status: 'approved', locked: true, image_url: '/x' }))
    renderPage()

    expect(await screen.findByRole('button', { name: /Reset character/ })).toBeInTheDocument()
  })
})
