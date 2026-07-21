import { render, screen } from '@testing-library/react'
import { MemoryRouter, Route, Routes } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { AdminProjectDetail } from '../../api/admin'
import { AdminProjectDetailPage } from './AdminProjectDetailPage'

const getProject = vi.fn()

vi.mock('../../api/admin', () => ({
  getProject: (...args: unknown[]) => getProject(...args),
  archiveProject: vi.fn(),
  resetCharacter: vi.fn(),
  retryCharacter: vi.fn(),
}))

const DETAIL: AdminProjectDetail = {
  project: {
    id: 7,
    user_id: 1,
    name: 'Aurora',
    slug: 'aurora',
    description: null,
    default_language: 'english',
    default_tone: 'warm',
    target_platforms: [],
    status: 'ready',
    active_character_id: 5,
    archived_at: null,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    status_changes: [
      {
        id: 1,
        from_status: 'draft',
        to_status: 'ready',
        reason: 'approved',
        actor_id: 1,
        created_at: '2026-01-02T00:00:00Z',
      },
    ],
  },
  owner: {
    id: 1,
    name: 'Ada',
    email: 'ada@example.com',
    role: 'user',
    status: 'active',
    email_verified: true,
    projects_count: 1,
    last_login_at: null,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
  },
  character: null,
  videos: [],
  generations: [],
}

describe('AdminProjectDetailPage', () => {
  beforeEach(() => {
    getProject.mockReset()
  })

  it('renders the inspection payload for a project', async () => {
    getProject.mockResolvedValue(DETAIL)

    render(
      <MemoryRouter initialEntries={['/admin/projects/7']}>
        <Routes>
          <Route path="/admin/projects/:id" element={<AdminProjectDetailPage />} />
        </Routes>
      </MemoryRouter>,
    )

    expect(await screen.findByRole('heading', { name: /Aurora/ })).toBeInTheDocument()
    expect(screen.getByText(/ada@example\.com/)).toBeInTheDocument()
    // Status-history entry renders the destination status in a <strong>.
    expect(screen.getByText('ready', { selector: 'strong' })).toBeInTheDocument()
    expect(getProject).toHaveBeenCalledWith(7)
  })
})
