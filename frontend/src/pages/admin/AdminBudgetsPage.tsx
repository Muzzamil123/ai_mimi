import { zodResolver } from '@hookform/resolvers/zod'
import { useCallback, useEffect, useState } from 'react'
import { useForm } from 'react-hook-form'
import { toast } from 'sonner'
import { z } from 'zod'
import {
  createBudgetPolicy,
  deleteBudgetPolicy,
  listBudgetPolicies,
  updateBudgetPolicy,
  type BudgetPolicy,
  type BudgetPolicyInput,
} from '../../api/adminCosts'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

const schema = z.object({
  scope_type: z.enum(['global', 'user', 'project']),
  scope_id: z.string(),
  provider: z.string(),
  daily_limit: z.string(),
  monthly_limit: z.string(),
  warning_percentage: z.string(),
  action_on_limit: z.enum(['warn', 'block']),
  enabled: z.boolean(),
})

type FormValues = z.infer<typeof schema>

const EMPTY: FormValues = {
  scope_type: 'global',
  scope_id: '',
  provider: '',
  daily_limit: '',
  monthly_limit: '',
  warning_percentage: '80',
  action_on_limit: 'warn',
  enabled: true,
}

function num(value: string): number | null {
  const trimmed = value.trim()
  if (trimmed === '') return null
  const parsed = Number(trimmed)
  return Number.isNaN(parsed) ? null : parsed
}

function toInput(values: FormValues): BudgetPolicyInput {
  return {
    scope_type: values.scope_type,
    scope_id: values.scope_type === 'global' ? null : num(values.scope_id),
    provider: values.provider.trim() === '' ? null : values.provider.trim(),
    daily_limit: num(values.daily_limit),
    monthly_limit: num(values.monthly_limit),
    warning_percentage: num(values.warning_percentage) ?? 80,
    action_on_limit: values.action_on_limit,
    enabled: values.enabled,
  }
}

function limitLabel(policy: BudgetPolicy): string {
  const parts: string[] = []
  if (policy.daily_limit != null) parts.push(`$${policy.daily_limit}/day`)
  if (policy.monthly_limit != null) parts.push(`$${policy.monthly_limit}/mo`)
  return parts.join(', ') || '—'
}

export function AdminBudgetsPage() {
  const [state, setState] = useState<
    { kind: 'loading' } | { kind: 'ready'; policies: BudgetPolicy[] } | { kind: 'error'; message: string }
  >({ kind: 'loading' })
  const [editingId, setEditingId] = useState<number | null>(null)

  const {
    register,
    handleSubmit,
    reset,
    watch,
    formState: { errors, isSubmitting },
  } = useForm<FormValues>({ resolver: zodResolver(schema), defaultValues: EMPTY })

  const scopeType = watch('scope_type')

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const { budget_policies } = await listBudgetPolicies()
      setState({ kind: 'ready', policies: budget_policies })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load budgets') })
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const startEdit = (policy: BudgetPolicy) => {
    setEditingId(policy.id)
    reset({
      scope_type: policy.scope_type,
      scope_id: policy.scope_id?.toString() ?? '',
      provider: policy.provider ?? '',
      daily_limit: policy.daily_limit?.toString() ?? '',
      monthly_limit: policy.monthly_limit?.toString() ?? '',
      warning_percentage: policy.warning_percentage.toString(),
      action_on_limit: policy.action_on_limit,
      enabled: policy.enabled,
    })
  }

  const cancelEdit = () => {
    setEditingId(null)
    reset(EMPTY)
  }

  const onSubmit = handleSubmit(async (values) => {
    try {
      if (editingId) {
        await updateBudgetPolicy(editingId, toInput(values))
        toast.success('Policy updated')
      } else {
        await createBudgetPolicy(toInput(values))
        toast.success('Policy created')
      }
      cancelEdit()
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to save policy'))
    }
  })

  const onDelete = async (policy: BudgetPolicy) => {
    if (!window.confirm('Delete this budget policy?')) return
    try {
      await deleteBudgetPolicy(policy.id)
      toast.success('Policy deleted')
      if (editingId === policy.id) cancelEdit()
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to delete policy'))
    }
  }

  return (
    <section className="admin-budgets">
      <div className="page-header">
        <h1>Budget policies</h1>
      </div>
      <p className="admin-muted">
        Limit spend per period across the platform, a user, or a project. A “block” policy prevents
        generation that would exceed it (admins may override); “warn” only surfaces a warning.
      </p>

      <form className="admin-form" onSubmit={onSubmit} noValidate>
        <h3>{editingId ? 'Edit policy' : 'Add policy'}</h3>
        <div className="admin-form-grid">
          <div className="field">
            <label htmlFor="scope_type">Scope</label>
            <select id="scope_type" {...register('scope_type')}>
              <option value="global">global</option>
              <option value="user">user</option>
              <option value="project">project</option>
            </select>
          </div>
          {scopeType !== 'global' && (
            <div className="field">
              <label htmlFor="scope_id">{scopeType} ID</label>
              <input id="scope_id" type="number" {...register('scope_id')} />
            </div>
          )}
          <div className="field">
            <label htmlFor="provider">Provider (optional)</label>
            <input id="provider" type="text" placeholder="all providers" {...register('provider')} />
          </div>
          <div className="field">
            <label htmlFor="daily_limit">Daily limit</label>
            <input id="daily_limit" type="number" step="0.01" {...register('daily_limit')} />
          </div>
          <div className="field">
            <label htmlFor="monthly_limit">Monthly limit</label>
            <input id="monthly_limit" type="number" step="0.01" {...register('monthly_limit')} />
          </div>
          <div className="field">
            <label htmlFor="warning_percentage">Warning %</label>
            <input id="warning_percentage" type="number" {...register('warning_percentage')} />
            {errors.warning_percentage && (
              <p className="field-error">{errors.warning_percentage.message}</p>
            )}
          </div>
          <div className="field">
            <label htmlFor="action_on_limit">Action on limit</label>
            <select id="action_on_limit" {...register('action_on_limit')}>
              <option value="warn">warn</option>
              <option value="block">block</option>
            </select>
          </div>
          <label className="checkbox-option">
            <input type="checkbox" {...register('enabled')} /> Enabled
          </label>
        </div>
        <div className="admin-actions">
          <button type="submit" disabled={isSubmitting}>
            {editingId ? 'Update policy' : 'Add policy'}
          </button>
          {editingId && (
            <button type="button" onClick={cancelEdit}>
              Cancel
            </button>
          )}
        </div>
      </form>

      {state.kind === 'loading' && <Loading label="Loading budgets…" />}
      {state.kind === 'error' && (
        <EmptyState
          title="Unable to load budgets"
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
                <th>Scope</th>
                <th>Provider</th>
                <th>Limits</th>
                <th>Warn %</th>
                <th>Action</th>
                <th>Enabled</th>
                <th>Actions</th>
              </tr>
            </thead>
            <tbody>
              {state.policies.length === 0 && (
                <tr>
                  <td colSpan={7} className="admin-muted">
                    No budget policies yet.
                  </td>
                </tr>
              )}
              {state.policies.map((policy) => (
                <tr key={policy.id}>
                  <td>
                    {policy.scope_type}
                    {policy.scope_id ? ` #${policy.scope_id}` : ''}
                  </td>
                  <td>{policy.provider ?? 'all'}</td>
                  <td>{limitLabel(policy)}</td>
                  <td>{policy.warning_percentage}%</td>
                  <td>
                    <span
                      className="status-badge"
                      data-tone={policy.action_on_limit === 'block' ? 'error' : 'progress'}
                    >
                      {policy.action_on_limit}
                    </span>
                  </td>
                  <td>
                    <span className="status-badge" data-tone={policy.enabled ? 'ok' : 'muted'}>
                      {policy.enabled ? 'enabled' : 'disabled'}
                    </span>
                  </td>
                  <td className="admin-row-actions">
                    <button type="button" className="link-button" onClick={() => startEdit(policy)}>
                      Edit
                    </button>
                    <button type="button" className="link-button" onClick={() => void onDelete(policy)}>
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
