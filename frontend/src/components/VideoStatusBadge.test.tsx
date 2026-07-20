import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { VideoStatusBadge } from './VideoStatusBadge'

describe('VideoStatusBadge', () => {
  it('renders a readable label for a status', () => {
    render(<VideoStatusBadge status="idea_ready" />)
    expect(screen.getByText('Idea ready')).toBeInTheDocument()
  })

  it('marks transcribing as in-progress', () => {
    render(<VideoStatusBadge status="transcribing" />)
    const badge = screen.getByText('Transcribing…')
    expect(badge).toHaveAttribute('data-tone', 'progress')
  })

  it('marks failed as an error', () => {
    render(<VideoStatusBadge status="failed" />)
    expect(screen.getByText('Failed')).toHaveAttribute('data-tone', 'error')
  })
})
