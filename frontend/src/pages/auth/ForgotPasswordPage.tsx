import { zodResolver } from '@hookform/resolvers/zod'
import { useState } from 'react'
import { useForm } from 'react-hook-form'
import { Link } from 'react-router-dom'
import { toast } from 'sonner'
import { z } from 'zod'
import { forgotPassword } from '../../api/auth'
import { EmptyState } from '../../components/EmptyState'
import { getErrorMessage } from '../../lib/errors'

const schema = z.object({
  email: z.string().min(1, 'Email is required').email('Enter a valid email'),
})

type FormValues = z.infer<typeof schema>

export function ForgotPasswordPage() {
  const [submitted, setSubmitted] = useState(false)
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema) })

  const onSubmit = handleSubmit(async (values) => {
    try {
      await forgotPassword(values.email)
      setSubmitted(true)
      toast.success('If that email exists, a reset link is on its way')
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to send reset email'))
    }
  })

  if (submitted) {
    return (
      <EmptyState
        title="Check your email"
        description="If an account exists for that address, we've sent a link to reset your password."
        action={<Link to="/login">Back to sign in</Link>}
      />
    )
  }

  return (
    <section className="auth-card">
      <h1>Reset your password</h1>
      <p className="auth-intro">Enter your email and we'll send you a reset link.</p>
      <form className="auth-form" onSubmit={onSubmit} noValidate>
        <div className="field">
          <label htmlFor="email">Email</label>
          <input id="email" type="email" autoComplete="email" {...register('email')} />
          {errors.email && <p className="field-error">{errors.email.message}</p>}
        </div>
        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Sending…' : 'Send reset link'}
        </button>
      </form>
      <p className="auth-links">
        <Link to="/login">Back to sign in</Link>
      </p>
    </section>
  )
}
