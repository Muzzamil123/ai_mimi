import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { Link, useNavigate } from 'react-router-dom'
import { toast } from 'sonner'
import { z } from 'zod'
import { createProject } from '../../api/projects'
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

export function NewProjectPage() {
  const navigate = useNavigate()
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: '',
      description: '',
      default_language: 'english',
      default_tone: '',
      target_platforms: [],
    },
  })

  const onSubmit = handleSubmit(async (values) => {
    try {
      const project = await createProject({
        name: values.name,
        description: values.description || undefined,
        default_language: values.default_language,
        default_tone: values.default_tone || undefined,
        target_platforms: values.target_platforms,
      })
      toast.success('Project created')
      navigate(`/projects/${project.id}`)
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to create project'))
    }
  })

  return (
    <section className="auth-card">
      <h1>New project</h1>
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
          <input
            id="default_tone"
            type="text"
            placeholder="e.g. friendly, professional"
            {...register('default_tone')}
          />
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
          {isSubmitting ? 'Creating…' : 'Create project'}
        </button>
      </form>
      <p className="auth-links">
        <Link to="/projects">Back to projects</Link>
      </p>
    </section>
  )
}
