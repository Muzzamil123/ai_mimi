import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import { NewProjectPage } from './NewProjectPage'

const createProject = vi.fn()

vi.mock('sonner', () => ({
  toast: { error: vi.fn(), success: vi.fn() },
}))

vi.mock('../../api/projects', () => ({
  createProject: (...args: unknown[]) => createProject(...args),
}))

function renderPage() {
  return render(
    <MemoryRouter initialEntries={['/projects/new']}>
      <NewProjectPage />
    </MemoryRouter>,
  )
}

describe('NewProjectPage', () => {
  beforeEach(() => {
    createProject.mockReset()
    createProject.mockResolvedValue({ id: 42 })
  })

  it('shows a validation error on empty submit', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.click(screen.getByRole('button', { name: 'Create project' }))

    expect(await screen.findByText('Name is required')).toBeInTheDocument()
    expect(createProject).not.toHaveBeenCalled()
  })

  it('calls createProject on a valid submit', async () => {
    const user = userEvent.setup()
    renderPage()

    await user.type(screen.getByLabelText('Name'), 'My new project')
    await user.click(screen.getByRole('button', { name: 'Create project' }))

    await waitFor(() =>
      expect(createProject).toHaveBeenCalledWith(
        expect.objectContaining({ name: 'My new project' }),
      ),
    )
  })
})
