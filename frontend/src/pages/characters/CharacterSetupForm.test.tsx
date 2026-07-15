import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { describe, expect, it, vi } from 'vitest'
import { CharacterSetupForm } from './CharacterSetupForm'

describe('CharacterSetupForm', () => {
  it('shows a validation error when the name is empty', async () => {
    const onSubmit = vi.fn()
    const user = userEvent.setup()
    render(<CharacterSetupForm submitLabel="Save character" onSubmit={onSubmit} />)

    await user.click(screen.getByRole('button', { name: 'Save character' }))

    expect(await screen.findByText('Name is required')).toBeInTheDocument()
    expect(onSubmit).not.toHaveBeenCalled()
  })

  it('submits name and compacted attributes, dropping blank fields', async () => {
    const onSubmit = vi.fn().mockResolvedValue(undefined)
    const user = userEvent.setup()
    render(<CharacterSetupForm submitLabel="Save character" onSubmit={onSubmit} />)

    await user.type(screen.getByLabelText('Name'), 'Rusty')
    await user.type(screen.getByLabelText('Species / type'), 'fox')
    await user.click(screen.getByRole('button', { name: 'Save character' }))

    await waitFor(() =>
      expect(onSubmit).toHaveBeenCalledWith(
        expect.objectContaining({
          name: 'Rusty',
          attributes: { species: 'fox' },
        }),
      ),
    )
    // Blank attribute/style fields are not sent.
    const [payload] = onSubmit.mock.calls[0]
    expect(payload.attributes.personality).toBeUndefined()
    expect(payload.style_preferences).toEqual({})
  })
})
