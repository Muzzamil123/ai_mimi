import { render, screen, waitFor } from '@testing-library/react'
import userEvent from '@testing-library/user-event'
import { MemoryRouter } from 'react-router-dom'
import { beforeEach, describe, expect, it, vi } from 'vitest'
import type { SettingRow, SettingsResponse } from '../../api/admin'
import { AdminSettingsPage } from './AdminSettingsPage'

const getSettings = vi.fn()
const updateSettings = vi.fn()

vi.mock('../../api/admin', () => ({
  getSettings: (...args: unknown[]) => getSettings(...args),
  updateSettings: (...args: unknown[]) => updateSettings(...args),
}))

const SETTINGS: SettingRow[] = [
  {
    key: 'email_sender_name',
    type: 'string',
    secret: false,
    description: 'Sender name',
    configured: true,
    value: 'Studio',
  },
  {
    key: 'openai_api_key',
    type: 'string',
    secret: true,
    description: 'OpenAI key',
    configured: true,
    value: null,
  },
]

function response(settings: SettingRow[]): SettingsResponse {
  return { settings }
}

function renderPage() {
  return render(
    <MemoryRouter>
      <AdminSettingsPage />
    </MemoryRouter>,
  )
}

describe('AdminSettingsPage', () => {
  beforeEach(() => {
    getSettings.mockReset()
    updateSettings.mockReset()
  })

  it('never renders a secret value and shows its configured badge', async () => {
    getSettings.mockResolvedValue(response(SETTINGS))
    renderPage()

    const secretInput = (await screen.findByLabelText(/openai_api_key/i)) as HTMLInputElement
    expect(secretInput.value).toBe('')
    expect(secretInput.type).toBe('password')
    expect(screen.getByText('configured')).toBeInTheDocument()
  })

  it('submits only changed keys', async () => {
    getSettings.mockResolvedValue(response(SETTINGS))
    updateSettings.mockResolvedValue(response(SETTINGS))
    renderPage()

    const senderInput = await screen.findByLabelText(/email_sender_name/i)
    await userEvent.clear(senderInput)
    await userEvent.type(senderInput, 'New Studio')
    await userEvent.click(screen.getByRole('button', { name: 'Save changes' }))

    await waitFor(() => expect(updateSettings).toHaveBeenCalledTimes(1))
    expect(updateSettings).toHaveBeenCalledWith({ email_sender_name: 'New Studio' })
  })
})
