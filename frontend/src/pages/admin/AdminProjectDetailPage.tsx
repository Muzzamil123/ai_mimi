import { useCallback, useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import {
  archiveProject,
  getProject,
  resetCharacter,
  retryCharacter,
  type AdminProjectDetail,
} from '../../api/admin'
import { CharacterStatusBadge } from '../../components/CharacterStatusBadge'
import { EmptyState } from '../../components/EmptyState'
import { GenerationStatusBadge } from '../../components/GenerationStatusBadge'
import { Loading } from '../../components/Loading'
import { ProjectStatusBadge } from '../../components/ProjectStatusBadge'
import { VideoStatusBadge } from '../../components/VideoStatusBadge'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; detail: AdminProjectDetail }
  | { kind: 'error'; message: string }

export function AdminProjectDetailPage() {
  const { id } = useParams<{ id: string }>()
  const projectId = Number(id)
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [busy, setBusy] = useState(false)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const detail = await getProject(projectId)
      setState({ kind: 'ready', detail })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load project') })
    }
  }, [projectId])

  useEffect(() => {
    void load()
  }, [load])

  const run = async (fn: () => Promise<unknown>, success: string, failure: string) => {
    setBusy(true)
    try {
      await fn()
      toast.success(success)
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, failure))
    } finally {
      setBusy(false)
    }
  }

  const onArchive = () => {
    if (!window.confirm('Archive this project?')) return
    void run(() => archiveProject(projectId), 'Project archived', 'Unable to archive project')
  }

  const onResetCharacter = () => {
    if (!window.confirm('Reset the approved character? This unlocks the project for regeneration.'))
      return
    const reason = window.prompt('Reason for reset:') ?? undefined
    void run(
      () => resetCharacter(projectId, reason || undefined),
      'Character reset',
      'Unable to reset character',
    )
  }

  const onRetryCharacter = () =>
    void run(
      () => retryCharacter(projectId),
      'Character generation restarted',
      'Unable to retry character generation',
    )

  if (state.kind === 'loading') return <Loading label="Loading project…" />
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

  const { project, owner, character, videos, generations } = state.detail

  return (
    <section className="admin-project-detail">
      <div className="page-header">
        <h1>
          {project.name} <ProjectStatusBadge status={project.status} />
        </h1>
        <Link to="/admin/projects">← All projects</Link>
      </div>

      <div className="admin-actions">
        {project.status !== 'archived' && (
          <button type="button" disabled={busy} onClick={onArchive}>
            Archive
          </button>
        )}
        {character && (
          <button type="button" disabled={busy} onClick={onResetCharacter}>
            Reset character
          </button>
        )}
        {character && character.status !== 'approved' && (
          <button type="button" disabled={busy} onClick={onRetryCharacter}>
            Retry character generation
          </button>
        )}
      </div>

      <div className="admin-card">
        <h3>Owner</h3>
        <p>
          {owner.name} — {owner.email}{' '}
          <span className="status-badge" data-tone={owner.status === 'active' ? 'ok' : 'error'}>
            {owner.status}
          </span>
        </p>
      </div>

      <div className="admin-card">
        <h3>Character</h3>
        {character ? (
          <p>
            {character.name} <CharacterStatusBadge status={character.status} />{' '}
            {character.locked && <span className="admin-muted">(locked)</span>}
          </p>
        ) : (
          <p className="admin-muted">No character generated yet.</p>
        )}
      </div>

      <div className="admin-card">
        <h3>Videos ({videos.length})</h3>
        {videos.length === 0 ? (
          <p className="admin-muted">No videos.</p>
        ) : (
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Title</th>
                  <th>Status</th>
                </tr>
              </thead>
              <tbody>
                {videos.map((video) => (
                  <tr key={video.id}>
                    <td>{video.id}</td>
                    <td>
                      <Link to={`/admin/videos?project_id=${project.id}`}>{video.title}</Link>
                    </td>
                    <td>
                      <VideoStatusBadge status={video.status} />
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="admin-card">
        <h3>Generations ({generations.length})</h3>
        {generations.length === 0 ? (
          <p className="admin-muted">No generations.</p>
        ) : (
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Variant</th>
                  <th>Status</th>
                  <th>Attempts</th>
                </tr>
              </thead>
              <tbody>
                {generations.map((generation) => (
                  <tr key={generation.id}>
                    <td>{generation.id}</td>
                    <td>{generation.label}</td>
                    <td>
                      <GenerationStatusBadge status={generation.status} />
                    </td>
                    <td>{generation.attempt_count}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>

      <div className="admin-card">
        <h3>Status history</h3>
        <ul className="status-history">
          {project.status_changes.map((change) => (
            <li key={change.id}>
              <span>
                {change.from_status ?? '—'} → <strong>{change.to_status}</strong>
              </span>
              {change.reason && <span className="admin-muted"> ({change.reason})</span>}
              <span className="admin-muted"> · {new Date(change.created_at).toLocaleString()}</span>
            </li>
          ))}
        </ul>
      </div>
    </section>
  )
}
