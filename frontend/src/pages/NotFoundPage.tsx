import { Link } from 'react-router-dom'
import { EmptyState } from '../components/EmptyState'

export function NotFoundPage() {
  return (
    <EmptyState
      title="404 — Page not found"
      description="The page you requested does not exist."
      action={<Link to="/">Go home</Link>}
    />
  )
}
