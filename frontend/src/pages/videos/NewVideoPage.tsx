import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import { z } from 'zod'
import { createVideo } from '../../api/videos'
import { getErrorMessage } from '../../lib/errors'
import { VIDEO_LANGUAGE_OPTIONS } from './options'

const schema = z.object({
  title: z.string().min(1, 'Title is required'),
  idea_text: z.string(),
  language: z.string().min(1, 'Language is required'),
  tone: z.string(),
})

type FormValues = z.infer<typeof schema>

export function NewVideoPage() {
  const { id } = useParams<{ id: string }>()
  const projectId = Number(id)
  const navigate = useNavigate()

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: { title: '', idea_text: '', language: 'english', tone: '' },
  })

  const submit = handleSubmit(async (values) => {
    try {
      const video = await createVideo(projectId, {
        title: values.title,
        idea_text: values.idea_text || undefined,
        language: values.language,
        tone: values.tone || undefined,
      })
      toast.success('Video created')
      navigate(`/projects/${projectId}/videos/${video.id}`)
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to create video'))
    }
  })

  return (
    <section className="auth-card">
      <h1>New video</h1>
      <p className="muted">
        Each video keeps its own idea and transcript. You can type an idea now or add one later —
        including by speaking it.
      </p>

      <form className="auth-form" onSubmit={submit} noValidate>
        <div className="field">
          <label htmlFor="video-title">Title</label>
          <input id="video-title" type="text" {...register('title')} />
          {errors.title && <p className="field-error">{errors.title.message}</p>}
        </div>

        <div className="field">
          <label htmlFor="video-idea">Idea (optional)</label>
          <textarea id="video-idea" rows={4} placeholder="Describe the video idea…" {...register('idea_text')} />
        </div>

        <div className="field">
          <label htmlFor="video-language">Language</label>
          <select id="video-language" {...register('language')}>
            {VIDEO_LANGUAGE_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
              </option>
            ))}
          </select>
          {errors.language && <p className="field-error">{errors.language.message}</p>}
        </div>

        <div className="field">
          <label htmlFor="video-tone">Tone (optional)</label>
          <input id="video-tone" type="text" placeholder="e.g. playful, formal" {...register('tone')} />
        </div>

        <button type="submit" disabled={isSubmitting}>
          {isSubmitting ? 'Creating…' : 'Create video'}
        </button>
      </form>

      <p className="auth-links">
        <Link to={`/projects/${projectId}/videos`}>Back to videos</Link>
      </p>
    </section>
  )
}
