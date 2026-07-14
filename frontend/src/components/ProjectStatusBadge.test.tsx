import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { ProjectStatusBadge } from './ProjectStatusBadge'

describe('ProjectStatusBadge', () => {
  it('renders a readable label for the draft status', () => {
    render(<ProjectStatusBadge status="draft" />)
    expect(screen.getByText('Draft')).toBeInTheDocument()
  })

  it('renders a readable label for the awaiting_character_approval status', () => {
    render(<ProjectStatusBadge status="awaiting_character_approval" />)
    expect(screen.getByText('Awaiting approval')).toBeInTheDocument()
  })

  it('renders a readable label for the ready status', () => {
    render(<ProjectStatusBadge status="ready" />)
    expect(screen.getByText('Ready')).toBeInTheDocument()
  })
})
