import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { GenerationStatusBadge } from './GenerationStatusBadge'

describe('GenerationStatusBadge', () => {
  it('renders processing as in-progress', () => {
    render(<GenerationStatusBadge status="processing" />)
    expect(screen.getByText('Processing…')).toHaveAttribute('data-tone', 'progress')
  })

  it('renders completed as ok', () => {
    render(<GenerationStatusBadge status="completed" />)
    expect(screen.getByText('Completed')).toHaveAttribute('data-tone', 'ok')
  })

  it('renders failed as error', () => {
    render(<GenerationStatusBadge status="failed" />)
    expect(screen.getByText('Failed')).toHaveAttribute('data-tone', 'error')
  })
})
