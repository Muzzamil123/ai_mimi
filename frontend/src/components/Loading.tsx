interface LoadingProps {
  label?: string
}

/** Reusable loading indicator with an accessible live region. */
export function Loading({ label = 'Loading…' }: LoadingProps) {
  return (
    <div className="loading" role="status" aria-live="polite">
      <span className="spinner" aria-hidden="true" />
      <span>{label}</span>
    </div>
  )
}
