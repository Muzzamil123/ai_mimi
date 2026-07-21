import { useCallback, useEffect, useState } from 'react'
import { toast } from 'sonner'
import { getSettings, updateSettings, type SettingRow } from '../../api/admin'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { getErrorMessage } from '../../lib/errors'

type DraftValue = string | boolean
type Draft = Record<string, DraftValue>

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; settings: SettingRow[] }
  | { kind: 'error'; message: string }

// Initial editable value for a setting. Secrets are write-only: always start
// blank so an existing secret is never rendered.
function initialDraft(row: SettingRow): DraftValue {
  if (row.type === 'boolean') return row.value === true
  if (row.secret) return ''
  return row.value === null || row.value === undefined ? '' : String(row.value)
}

function buildDraft(settings: SettingRow[]): Draft {
  return Object.fromEntries(settings.map((row) => [row.key, initialDraft(row)]))
}

// Whether a field's draft differs from its persisted value (secrets: any input).
function isChanged(row: SettingRow, value: DraftValue): boolean {
  if (row.secret) return typeof value === 'string' && value.length > 0
  if (row.type === 'boolean') return value !== (row.value === true)
  const original = row.value === null || row.value === undefined ? '' : String(row.value)
  return value !== original
}

export function AdminSettingsPage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [draft, setDraft] = useState<Draft>({})
  const [saving, setSaving] = useState(false)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const { settings } = await getSettings()
      setState({ kind: 'ready', settings })
      setDraft(buildDraft(settings))
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load settings') })
    }
  }, [])

  useEffect(() => {
    void load()
  }, [load])

  const onSubmit = async (event: React.FormEvent) => {
    event.preventDefault()
    if (state.kind !== 'ready') return

    const changes: Record<string, string | boolean> = {}
    for (const row of state.settings) {
      const value = draft[row.key]
      if (isChanged(row, value)) changes[row.key] = value
    }

    if (Object.keys(changes).length === 0) {
      toast.info('No changes to save')
      return
    }

    setSaving(true)
    try {
      const { settings } = await updateSettings(changes)
      toast.success('Settings saved')
      setState({ kind: 'ready', settings })
      setDraft(buildDraft(settings))
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to save settings'))
    } finally {
      setSaving(false)
    }
  }

  if (state.kind === 'loading') return <Loading label="Loading settings…" />
  if (state.kind === 'error') {
    return (
      <EmptyState
        title="Unable to load settings"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  return (
    <section className="admin-settings">
      <div className="page-header">
        <h1>Platform settings</h1>
      </div>
      <p className="admin-muted">
        Secret values are never displayed. Leave a secret field blank to keep its current value.
      </p>

      <form className="admin-settings-form" onSubmit={onSubmit} noValidate>
        {state.settings.map((row) => (
          <div className="field" key={row.key}>
            <label htmlFor={`setting-${row.key}`}>
              {row.key}
              {row.secret && (
                <span className="status-badge" data-tone={row.configured ? 'ok' : 'muted'}>
                  {row.configured ? 'configured' : 'not set'}
                </span>
              )}
            </label>
            <p className="admin-muted">{row.description}</p>

            {row.type === 'boolean' ? (
              <label className="checkbox-option">
                <input
                  id={`setting-${row.key}`}
                  type="checkbox"
                  checked={draft[row.key] === true}
                  onChange={(event) =>
                    setDraft((prev) => ({ ...prev, [row.key]: event.target.checked }))
                  }
                />
                Enabled
              </label>
            ) : (
              <input
                id={`setting-${row.key}`}
                type={row.secret ? 'password' : row.type === 'integer' ? 'number' : 'text'}
                autoComplete={row.secret ? 'new-password' : 'off'}
                placeholder={row.secret && row.configured ? '•••••••• (unchanged)' : ''}
                value={typeof draft[row.key] === 'string' ? (draft[row.key] as string) : ''}
                onChange={(event) =>
                  setDraft((prev) => ({ ...prev, [row.key]: event.target.value }))
                }
              />
            )}
          </div>
        ))}

        <button type="submit" disabled={saving}>
          {saving ? 'Saving…' : 'Save changes'}
        </button>
      </form>
    </section>
  )
}
