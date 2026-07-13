import { Component, type ErrorInfo, type ReactNode } from 'react'

interface Props {
  children: ReactNode
  fallback?: ReactNode
}

interface State {
  hasError: boolean
  error?: Error
}

/** Catches render-time errors anywhere in the tree and shows a recoverable fallback. */
export class ErrorBoundary extends Component<Props, State> {
  state: State = { hasError: false }

  static getDerivedStateFromError(error: Error): State {
    return { hasError: true, error }
  }

  componentDidCatch(error: Error, info: ErrorInfo): void {
    // Phase 13 wires this to an error-tracking provider (e.g. Sentry).
    console.error('Unhandled UI error:', error, info)
  }

  private handleReset = (): void => {
    this.setState({ hasError: false, error: undefined })
  }

  render(): ReactNode {
    if (this.state.hasError) {
      return (
        this.props.fallback ?? (
          <div role="alert" className="error-boundary">
            <h1>Something went wrong</h1>
            <p>{this.state.error?.message ?? 'An unexpected error occurred.'}</p>
            <button type="button" onClick={this.handleReset}>
              Try again
            </button>
          </div>
        )
      )
    }
    return this.props.children
  }
}
