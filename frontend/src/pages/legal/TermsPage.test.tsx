import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { TermsPage } from './TermsPage'

describe('TermsPage', () => {
  it('renders the terms of service with key sections', () => {
    render(<TermsPage />)
    expect(screen.getByRole('heading', { name: 'Terms of Service', level: 1 })).toBeInTheDocument()
    expect(screen.getByRole('heading', { name: 'Acceptable use' })).toBeInTheDocument()
  })
})
