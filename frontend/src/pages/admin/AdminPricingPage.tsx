import { zodResolver } from '@hookform/resolvers/zod'
import { useCallback, useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { z } from 'zod'
import {
  createProviderPrice,
  deleteProviderPrice,
  listProviderPrices,
  updateProviderPrice,
  SERVICE_TYPES,
  type ProviderPrice,
  type ProviderPriceInput,
} from '../../api/adminCosts'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

const RATE_FIELDS = [
  'per_input_token',
  'per_output_token',
  'per_image',
  'per_second',
  'per_request',
] as const

const schema = z.object({
  provider: z.string().min(1, 'Provider is required'),
  service_type: z.enum(['character_image', 'text_generation', 'speech_to_text', 'video_generation']),
  model: z.string(),
  currency: z.string().min(1),
  enabled: z.boolean(),
  per_input_token: z.string(),
  per_output_token: z.string(),
  per_image: z.string(),
  per_second: z.string(),
  per_request: z.string(),
})

type FormValues = z.infer<typeof schema>

const EMPTY: FormValues = {
  provider: '',
  service_type: 'video_generation',
  model: '',
  currency: 'USD',
  enabled: true,
  per_input_token: '',
  per_output_token: '',
  per_image: '',
  per_second: '',
  per_request: '',
}

function toInput(values: FormValues): ProviderPriceInput {
  const input: ProviderPriceInput = {
    provider: values.provider.trim(),
    service_type: values.service_type,
    model: values.model.trim(),
    currency: values.currency.trim(),
    enabled: values.enabled,
  }
  for (const field of RATE_FIELDS) {
    input[field] = values[field].trim() === '' ? null : values[field].trim()
  }
  return input
}

export function AdminPricingPage() {
  const [state, setState] = useState<
    { kind: 'loading' } | { kind: 'ready'; prices: ProviderPrice[] } | { kind: 'error'; message: string }
  >({ kind: 'loading' })
  const [editingId, setEditingId] = useState<number | null>(null)

  const {
    register,
    handleSubmit,
    reset,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema), defaultValues: EMPTY })

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const { provider_prices } = await listProviderPrices()
      setState({ kind: 'ready', prices: provider_prices })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load pricing') })
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const startEdit = (price: ProviderPrice) => {
    setEditingId(price.id)
    reset({
      provider: price.provider,
      service_type: price.service_type,
      model: price.model ?? '',
      currency: price.currency,
      enabled: price.enabled,
      per_input_token: price.per_input_token ?? '',
      per_output_token: price.per_output_token ?? '',
      per_image: price.per_image ?? '',
      per_second: price.per_second ?? '',
      per_request: price.per_request ?? '',
    })
  }

  const cancelEdit = () => {
    setEditingId(null)
    reset(EMPTY)
  }

  const onSubmit = handleSubmit(async (values) => {
    try {
      if (editingId) {
        await updateProviderPrice(editingId, toInput(values))
        toast.success('Price updated')
      } else {
        await createProviderPrice(toInput(values))
        toast.success('Price created')
      }
      cancelEdit()
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to save price'))
    }
  })

  const onDelete = async (price: ProviderPrice) => {
    if (!window.confirm(`Delete pricing for ${price.provider}/${price.service_type}?`)) return
    try {
      await deleteProviderPrice(price.id)
      toast.success('Price deleted')
      if (editingId === price.id) cancelEdit()
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to delete price'))
    }
  }

  return (
    <section className="admin-pricing">
      <div className="page-header">
        <h1>Provider pricing</h1>
      </div>
      <p className="admin-muted">
        Configure per-unit rates so cost is calculated from these values. A blank model is the
        default for a provider/service; a model-specific row overrides it.
      </p>

      <form className="admin-form" onSubmit={onSubmit} noValidate>
        <h3>{editingId ? 'Edit price' : 'Add price'}</h3>
        <div className="admin-form-grid">
          <div className="field">
            <label htmlFor="provider">Provider</label>
            <input id="provider" type="text" placeholder="openai / gemini / google_labs" {...register('provider')} />
            {errors.provider && <p className="field-error">{errors.provider.message}</p>}
          </div>
          <div className="field">
            <label htmlFor="service_type">Service</label>
            <select id="service_type" {...register('service_type')}>
              {SERVICE_TYPES.map((service) => (
                <option key={service} value={service}>
                  {service}
                </option>
              ))}
            </select>
          </div>
          <div className="field">
            <label htmlFor="model">Model (optional)</label>
            <input id="model" type="text" {...register('model')} />
          </div>
          <div className="field">
            <label htmlFor="currency">Currency</label>
            <input id="currency" type="text" {...register('currency')} />
          </div>
          {RATE_FIELDS.map((field) => (
            <div className="field" key={field}>
              <label htmlFor={field}>{field}</label>
              <input id={field} type="text" inputMode="decimal" placeholder="0.0" {...register(field)} />
            </div>
          ))}
          <label className="checkbox-option">
            <input type="checkbox" {...register('enabled')} /> Enabled
          </label>
        </div>
        <div className="admin-actions">
          <button type="submit" disabled={isSubmitting}>
            {editingId ? 'Update price' : 'Add price'}
          </button>
          {editingId && (
            <button type="button" onClick={cancelEdit}>
              Cancel
            </button>
          )}
        </div>
      </form>

      {state.kind === 'loading' && <Loading label="Loading pricing…" />}
      {state.kind === 'error' && (
        <EmptyState
          title="Unable to load pricing"
          description={state.message}
          action={
            <button type="button" onClick={() => void load()}>
              Retry
            </button>
          }
        />
      )}
      {state.kind === 'ready' && (
        <div className="table-scroll">
          <table className="data-table">
            <thead>
              <tr>
                <th>Provider</th>
                <th>Service</th>
                <th>Model</th>
                <th>Rates</th>
                <th>Enabled</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {state.prices.length === 0 && (
                <tr>
                  <td colSpan={6} className="admin-muted">
                    No pricing configured yet.
                  </td>
                </tr>
              )}
              {state.prices.map((price) => (
                <tr key={price.id}>
                  <td>{price.provider}</td>
                  <td>{price.service_type}</td>
                  <td>{price.model || <span className="admin-muted">(default)</span>}</td>
                  <td className="admin-muted">
                    {RATE_FIELDS.filter((f) => price[f]).map((f) => `${f}=${price[f]}`).join(', ') || '—'}
                  </td>
                  <td>
                    <span className="status-badge" data-tone={price.enabled ? 'ok' : 'muted'}>
                      {price.enabled ? 'enabled' : 'disabled'}
                    </span>
                  </td>
                  <td className="admin-row-actions">
                    <button type="button" className="link-button" onClick={() => startEdit(price)}>
                      Edit
                    </button>
                    <button type="button" className="link-button" onClick={() => void onDelete(price)}>
                      Delete
                    </button>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}
    </section>
  )
}
