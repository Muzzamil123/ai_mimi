import { useEffect, useRef, useState } from 'react'
import { Link, useSearchParams } from 'react-router-dom'
import { verifyEmail } from '../../api/auth'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

type VerifyState =
  | { kind: 'idle' }
  | { kind: 'verifying' }
  | { kind: 'success' }
  | { kind: 'error'; message: string }

export function VerifyEmailPage() {
  const [searchParams] = useSearchParams()
  const token = searchParams.get('token')
  const [state, setState] = useState<VerifyState>(token ? { kind: 'verifying' } : { kind: 'idle' })
  const attempted = useRef(false)

  useEffect(() => {
    if (!token || attempted.current) return
    attempted.current = true

    let active = true
    void (async () => {
      try {
        await verifyEmail(token)
        if (active) setState({ kind: 'success' })
      } catch (err) {
        if (active)
          setState({ kind: 'error', message: getErrorMessage(err, 'Verification failed') })
      }
    })()

    return () => {
      active = false
    }
  }, [token])

  if (!token) {
    return (
      <EmptyState
        title="Invalid verification link"
        description="This email verification link is missing or malformed."
        action={<Link to="/login">Back to sign in</Link>}
      />
    )
  }

  if (state.kind === 'verifying') {
    return <Loading label="Verifying your email…" />
  }

  if (state.kind === 'success') {
    return (
      <EmptyState
        title="Email verified"
        description="Your email address has been confirmed. You can now sign in."
        action={<Link to="/login">Continue to sign in</Link>}
      />
    )
  }

  if (state.kind === 'error') {
    return (
      <EmptyState
        title="Verification failed"
        description={state.message}
        action={<Link to="/login">Back to sign in</Link>}
      />
    )
  }

  return null
}
