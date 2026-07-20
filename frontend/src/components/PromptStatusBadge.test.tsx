import { render, screen } from '@testing-library/react'
import { describe, expect, it } from 'vitest'
import { PromptStatusBadge } from './PromptStatusBadge'

describe('PromptStatusBadge', () => {
  it('renders a readable label', () => {
    render(<PromptStatusBadge status="approved" />)
    expect(screen.getByText('Approved')).toHaveAttribute('data-tone', 'ok')
  })

  it('marks generating as in-progress', () => {
    render(<PromptStatusBadge status="generating" />)
    expect(screen.getByText('Generating…')).toHaveAttribute('data-tone', 'progress')
  })

  it('marks superseded as muted', () => {
    render(<PromptStatusBadge status="superseded" />)
    expect(screen.getByText('Superseded')).toHaveAttribute('data-tone', 'muted')
  })
})
