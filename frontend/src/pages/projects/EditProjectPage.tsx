import { zodResolver } from '@hookform/resolvers/zod'
import { useCallback, useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import { z } from 'zod'
import { getProject, updateProject, type ProjectDetail } from '../../api/projects'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'
import { LANGUAGE_OPTIONS, PLATFORM_OPTIONS } from './options'

const schema = z.object({
  name: z.string().min(1, 'Name is required'),
  description: z.string(),
  default_language: z.string(),
  default_tone: z.string(),
  target_platforms: z.array(z.string()),
})

type FormValues = z.infer<typeof schema>

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; project: ProjectDetail }
  | { kind: 'not-found' }
  | { kind: 'error'; message: string }

export function EditProjectPage() {
  const { id } = useParams<{ id: string }>()
  const projectId = Number(id)
  const navigate = useNavigate()
  const [state, setState] = useState<LoadState>({ kind: 'loading' })

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema) })

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const project = await getProject(projectId)
      setState({ kind: 'ready', project })
      reset({
        name: project.name,
        description: project.description ?? '',
        default_language: project.default_language,
        default_tone: project.default_tone,
        target_platforms: project.target_platforms,
      })
    } catch (err) {
      const status = (err as { status?: number }).status
      if (status === 404) {
        setState({ kind: 'not-found' })
        return
      }
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load project') })
    }
  }, [projectId, reset])

  useEffect(() => {
    void load()
  }, [load])

  const onSubmit = handleSubmit(async (values) => {
    try {
      await updateProject(projectId, {
        name: values.name,
        description: values.description || undefined,
        default_language: values.default_language,
        default_tone: values.default_tone || undefined,
        target_platforms: values.target_platforms,
      })
      toast.success('Project updated')
      navigate(`/projects/${projectId}`)
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to update project'))
    }
  })

  if (state.kind === 'loading') {
    return <Loading label="Loading project…" />
  }

  if (state.kind === 'not-found') {
    return (
      <EmptyState
        title="Project not found"
        description="This project does not exist or you do not have access to it."
        action={<Link to="/projects">Back to projects</Link>}
      />
    )
  }

  if (state.kind === 'error') {
    return (
      <EmptyState
        title="Unable to load project"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  if (state.project.status !== 'draft') {
    return (
      <EmptyState
        title="This project can’t be edited"
        description="Only draft projects can be edited once character initialization has started."
        action={<Link to={`/projects/${projectId}`}>Back to project</Link>}
      />
    )
  }

  return (
    <section className="auth-card">
      <h1>Edit project</h1>
      <form className="auth-form" onSubmit={onSubmit} noValidate>
        <div className="field">
          <label htmlFor="name">Name</label>
          <input id="name" type="text" {...register('name')} />
          {errors.name && <p className="field-error">{errors.name.message}</p>}
        </div>

        <div className="field">
          <label htmlFor="description">Description</label>
          <textarea id="description" rows={3} {...register('description')} />
        </div>

        <div className="field">
          <label htmlFor="default_language">Default language</label>
          <select id="default_language" {...register('default_language')}>
            {LANGUAGE_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
        </div>

        <div className="field">
          <label htmlFor="default_tone">Default tone</label>
          <input id="default_tone" type="text" {...register('default_tone')} />
        </div>

        <fieldset className="field checkbox-group">
          <legend>Target platforms</legend>
          {PLATFORM_OPTIONS.map((option) => (
            <label key={option.value} className="checkbox-option">
              <input type="checkbox" value={option.value} {...register('target_platforms')} />
              {option.label}
            </label>
          ))}
        </fieldset>

        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Saving…' : 'Save changes'}
        </button>
      </form>
      <p className="auth-links">
        <Link to={`/projects/${projectId}`}>Cancel</Link>
      </p>
    </section>
  )
}
