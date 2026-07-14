import { render, screen } from '@testing-library/react'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { Project, ProjectListResponse } from '../../api/projects'
import { ProjectsListPage } from './ProjectsListPage'

const listProjects = vi.fn()

vi.mock('../../api/projects', () => ({
  listProjects: (...args: unknown[]) => listProjects(...args),
}))

function makeProject(overrides: Partial<Project> = {}): Project {
  return {
    id: 1,
    user_id: 1,
    name: 'My project',
    slug: 'my-project',
    description: null,
    default_language: 'english',
    default_tone: '',
    target_platforms: [],
    status: 'draft',
    active_character_id: null,
    archived_at: null,
    created_at: '2026-01-01T00:00:00Z',
    updated_at: '2026-01-01T00:00:00Z',
    ...overrides,
  }
}

function response(projects: Project[]): ProjectListResponse {
  return {
    projects,
    meta: { page: 1, per_page: 10, total_count: projects.length, total_pages: 1 },
  }
}

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/projects']}>
      <ProjectsListPage />
    </MemoryRouter>,
  )
}

describe('ProjectsListPage', () => {
  beforeEach(() => {
    listProjects.mockReset()
  })

  it('renders a list of projects', async () => {
    listProjects.mockResolvedValue(
      response([
        makeProject({ id: 1, name: 'Alpha' }),
        makeProject({ id: 2, name: 'Beta', status: 'ready' }),
      ]),
    )
    renderPage()

    expect(await screen.findByRole('link', { name: 'Alpha' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: 'Beta' })).toBeInTheDocument()
    expect(screen.getByText('Ready', { selector: '.status-badge' })).toBeInTheDocument()
  })

  it('shows the empty state when there are no projects', async () => {
    listProjects.mockResolvedValue(response([]))
    renderPage()

    expect(await screen.findByText('No projects yet')).toBeInTheDocument()
  })
})
