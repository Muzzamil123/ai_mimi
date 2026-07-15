import { zodResolver } from '@hookform/resolvers/zod'
import { useForm } from 'react-hook-form'
import { z } from 'zod'
import type { CharacterInput } from '../../api/characters'
import { ATTRIBUTE_FIELDS, STYLE_FIELDS, compact } from './fields'

const schema = z.object({
  name: z.string().min(1, 'Name is required'),
  description: z.string(),
  attributes: z.record(z.string(), z.string()),
  style_preferences: z.record(z.string(), z.string()),
})

type FormValues = z.infer<typeof schema>

interface CharacterSetupFormProps {
  initial?: {
    name?: string
    description?: string | null
    attributes?: Record<string, string>
    style_preferences?: Record<string, string>
  }
  submitLabel: string
  onSubmit: (input: CharacterInput) => Promise<void>
}

function emptyRecord(fields: { key: string }[], values?: Record<string, string>) {
  return Object.fromEntries(fields.map((f) => [f.key, values?.[f.key] ?? '']))
}

/** Character setup + attributes form, used for both initial setup and edits. */
export function CharacterSetupForm({ initial, submitLabel, onSubmit }: CharacterSetupFormProps) {
  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({
    resolver: zodResolver(schema),
    defaultValues: {
      name: initial?.name ?? '',
      description: initial?.description ?? '',
      attributes: emptyRecord(ATTRIBUTE_FIELDS, initial?.attributes),
      style_preferences: emptyRecord(STYLE_FIELDS, initial?.style_preferences),
    },
  })

  const submit = handleSubmit(async (values) => {
    await onSubmit({
      name: values.name,
      description: values.description || undefined,
      attributes: compact(values.attributes),
      style_preferences: compact(values.style_preferences),
    })
  })

  return (
    <form className="auth-form" onSubmit={submit} noValidate>
      <div className="field">
        <label htmlFor="character-name">Name</label>
        <input id="character-name" type="text" {...register('name')} />
        {errors.name && <p className="field-error">{errors.name.message}</p>}
      </div>

      <div className="field">
        <label htmlFor="character-description">Description</label>
        <textarea id="character-description" rows={3} {...register('description')} />
      </div>

      <fieldset className="field">
        <legend>Attributes</legend>
        {ATTRIBUTE_FIELDS.map((f) => (
          <div className="field" key={f.key}>
            <label htmlFor={`attr-${f.key}`}>{f.label}</label>
            <input
              id={`attr-${f.key}`}
              type="text"
              placeholder={f.placeholder}
              {...register(`attributes.${f.key}`)}
            />
          </div>
        ))}
      </fieldset>

      <fieldset className="field">
        <legend>Style preferences</legend>
        {STYLE_FIELDS.map((f) => (
          <div className="field" key={f.key}>
            <label htmlFor={`style-${f.key}`}>{f.label}</label>
            <input
              id={`style-${f.key}`}
              type="text"
              placeholder={f.placeholder}
              {...register(`style_preferences.${f.key}`)}
            />
          </div>
        ))}
      </fieldset>

      <button type="submit" disabled={isSubmitting}>
        {isSubmitting ? 'Saving…' : submitLabel}
      </button>
    </form>
  )
}
