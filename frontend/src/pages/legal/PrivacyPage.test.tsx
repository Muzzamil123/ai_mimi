import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { PrivacyPage } from './PrivacyPage'

describe('PrivacyPage', () => {
  it('renders the privacy policy with key sections and a support contact', () => {
    render(<PrivacyPage />)
    expect(screen.getByRole('heading', { name: 'Privacy Policy', level: 1 })).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Account deletion' })).toBeInTheDocument()
    expect(screen.getByRole('link', { name: /support@aicvp.example/ })).toHaveAttribute(
      'href',
      'mailto:support@aicvp.example',
    )
  })
})
