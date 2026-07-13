import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { z } from 'zod'
import { useAuth } from '../../auth/AuthContext'
import { EmptyState } from '../../components/EmptyState'
import { getErrorMessage } from '../../lib/errors'

const profileSchema = z.object({
  name: z.string().min(1, 'Name is required'),
})
type ProfileValues = z.infer<typeof profileSchema>

const passwordSchema = z
  .object({
    current_password: z.string().min(1, 'Current password is required'),
    password: z.string().min(8, 'Password must be at least 8 characters'),
    confirmPassword: z.string().min(1, 'Confirm your new password'),
  })
  .refine((values) => values.password === values.confirmPassword, {
    message: 'Passwords do not match',
    path: ['confirmPassword'],
  })
type PasswordValues = z.infer<typeof passwordSchema>

export function ProfilePage() {
  const { user, updateProfile, deleteAccount } = useAuth()
  const navigate = useNavigate()

  const profileForm = useForm<ProfileValues>({
    resolver: zodResolver(profileSchema),
    values: { name: user?.name ?? '' },
  })

  const passwordForm = useForm<PasswordValues>({
    resolver: zodResolver(passwordSchema),
  })

  if (!user) {
    return <EmptyState title="Not signed in" description="Your profile is unavailable." />
  }

  const onUpdateProfile = profileForm.handleSubmit(async (values) => {
    try {
      await updateProfile({ name: values.name })
      toast.success('Profile updated')
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to update profile'))
    }
  })

  const onChangePassword = passwordForm.handleSubmit(async (values) => {
    try {
      await updateProfile({
        password: values.password,
        current_password: values.current_password,
      })
      passwordForm.reset()
      toast.success('Password changed')
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to change password'))
    }
  })

  const onDelete = async () => {
    if (!window.confirm('Delete your account? This cannot be undone.')) return
    try {
      await deleteAccount()
      toast.success('Account deleted')
      navigate('/login', { replace: true })
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to delete account'))
    }
  }

  return (
    <section className="profile">
      <h1>Your profile</h1>
      <dl className="profile-summary">
        <div>
          <dt>Name</dt>
          <dd>{user.name}</dd>
        </div>
        <div>
          <dt>Email</dt>
          <dd>{user.email}</dd>
        </div>
        <div>
          <dt>Role</dt>
          <dd>{user.role}</dd>
        </div>
        <div>
          <dt>Email verified</dt>
          <dd data-status={user.email_verified ? 'ok' : 'unknown'}>
            {user.email_verified ? 'Yes' : 'No'}
          </dd>
        </div>
      </dl>

      <form className="auth-form" onSubmit={onUpdateProfile} noValidate>
        <h2>Update name</h2>
        <div className="field">
          <label htmlFor="name">Name</label>
          <input id="name" type="text" {...profileForm.register('name')} />
          {profileForm.formState.errors.name && (
            <p className="field-error">{profileForm.formState.errors.name.message}</p>
          )}
        </div>
        <button type="submit" disabled={profileForm.formState.isSubmitting}>
          {profileForm.formState.isSubmitting ? 'Saving…' : 'Save name'}
        </button>
      </form>

      <form className="auth-form" onSubmit={onChangePassword} noValidate>
        <h2>Change password</h2>
        <div className="field">
          <label htmlFor="current_password">Current password</label>
          <input
            id="current_password"
            type="password"
            autoComplete="current-password"
            {...passwordForm.register('current_password')}
          />
          {passwordForm.formState.errors.current_password && (
            <p className="field-error">{passwordForm.formState.errors.current_password.message}</p>
          )}
        </div>
        <div className="field">
          <label htmlFor="new_password">New password</label>
          <input
            id="new_password"
            type="password"
            autoComplete="new-password"
            {...passwordForm.register('password')}
          />
          {passwordForm.formState.errors.password && (
            <p className="field-error">{passwordForm.formState.errors.password.message}</p>
          )}
        </div>
        <div className="field">
          <label htmlFor="confirm_password">Confirm new password</label>
          <input
            id="confirm_password"
            type="password"
            autoComplete="new-password"
            {...passwordForm.register('confirmPassword')}
          />
          {passwordForm.formState.errors.confirmPassword && (
            <p className="field-error">{passwordForm.formState.errors.confirmPassword.message}</p>
          )}
        </div>
        <button type="submit" disabled={passwordForm.formState.isSubmitting}>
          {passwordForm.formState.isSubmitting ? 'Saving…' : 'Change password'}
        </button>
      </form>

      <div className="danger-zone">
        <h2>Danger zone</h2>
        <p>Deleting your account is permanent and cannot be undone.</p>
        <button type="button" className="danger" onClick={() => void onDelete()}>
          Delete account
        </button>
      </div>
    </section>
  )
}
