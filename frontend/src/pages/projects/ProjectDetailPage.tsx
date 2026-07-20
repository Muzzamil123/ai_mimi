import { useCallback, useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { toast } from 'sonner'
import {
  archiveProject,
  deleteProject,
  getProject,
  restoreProject,
  type ProjectDetail,
} from '../../api/projects'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { ProjectStatusBadge } from '../../components/ProjectStatusBadge'
import { getErrorMessage } from '../../lib/errors'
import { formatLanguage, formatPlatform } from './options'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; project: ProjectDetail }
  | { kind: 'not-found' }
  | { kind: 'error'; message: string }

export function ProjectDetailPage() {
  const { id } = useParams<{ id: string }>()
  const projectId = Number(id)
  const navigate = useNavigate()
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [busy, setBusy] = useState(false)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const project = await getProject(projectId)
      setState({ kind: 'ready', project })
    } catch (err) {
      const status = (err as { status?: number }).status
      if (status === 404) {
        setState({ kind: 'not-found' })
        return
      }
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load project') })
    }
  }, [projectId])

  useEffect(() => {
    void load()
  }, [load])

  const onArchive = async () => {
    if (!window.confirm('Archive this project? You can restore it later.')) return
    setBusy(true)
    try {
      await archiveProject(projectId)
      toast.success('Project archived')
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to archive project'))
    } finally {
      setBusy(false)
    }
  }

  const onRestore = async () => {
    setBusy(true)
    try {
      await restoreProject(projectId)
      toast.success('Project restored')
      await load()
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to restore project'))
    } finally {
      setBusy(false)
    }
  }

  const onDelete = async () => {
    if (!window.confirm('Delete this project? This cannot be undone.')) return
    setBusy(true)
    try {
      await deleteProject(projectId)
      toast.success('Project deleted')
      navigate('/projects', { replace: true })
    } catch (err) {
      toast.error(getErrorMessage(err, 'Unable to delete project'))
      setBusy(false)
    }
  }

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

  const { project } = state
  const isArchived = project.status === 'archived'
  const isDraft = project.status === 'draft'

  return (
    <section className="project-detail">
      <div className="page-header">
        <div className="page-header__title">
          <h1>{project.name}</h1>
          <ProjectStatusBadge status={project.status} />
        </div>
        <div className="project-actions">
          {isDraft && (
            <button type="button" onClick={() => navigate(`/projects/${projectId}/edit`)}>
              Edit
            </button>
          )}
          {!isArchived && (
            <button type="button" onClick={() => navigate(`/projects/${projectId}/character`)}>
              Manage character
            </button>
          )}
          {project.status === 'ready' && (
            <button type="button" onClick={() => navigate(`/projects/${projectId}/videos`)}>
              Videos
            </button>
          )}
          {isArchived ? (
            <button type="button" disabled={busy} onClick={() => void onRestore()}>
              Restore
            </button>
          ) : (
            <button type="button" disabled={busy} onClick={() => void onArchive()}>
              Archive
            </button>
          )}
          {isDraft && (
            <button type="button" className="danger" disabled={busy} onClick={() => void onDelete()}>
              Delete
            </button>
          )}
        </div>
      </div>

      <dl className="profile-summary">
        <div>
          <dt>Slug</dt>
          <dd>{project.slug}</dd>
        </div>
        <div>
          <dt>Default language</dt>
          <dd>{formatLanguage(project.default_language)}</dd>
        </div>
        <div>
          <dt>Default tone</dt>
          <dd>{project.default_tone || '—'}</dd>
        </div>
        <div>
          <dt>Target platforms</dt>
          <dd>
            {project.target_platforms.length > 0
              ? project.target_platforms.map(formatPlatform).join(', ')
              : '—'}
          </dd>
        </div>
        <div>
          <dt>Created</dt>
          <dd>{new Date(project.created_at).toLocaleString()}</dd>
        </div>
        <div>
          <dt>Updated</dt>
          <dd>{new Date(project.updated_at).toLocaleString()}</dd>
        </div>
      </dl>

      {project.description && (
        <div className="project-description">
          <h2>Description</h2>
          <p>{project.description}</p>
        </div>
      )}

      <div className="status-history">
        <h2>Status history</h2>
        {project.status_changes.length === 0 ? (
          <p className="muted">No status changes recorded yet.</p>
        ) : (
          <ol className="timeline">
            {project.status_changes.map((change) => (
              <li key={change.id}>
                <span className="timeline__status">
                  {change.from_status ? `${change.from_status} → ` : ''}
                  {change.to_status}
                </span>
                <span className="timeline__meta">
                  {new Date(change.created_at).toLocaleString()}
                  {change.reason ? ` — ${change.reason}` : ''}
                </span>
              </li>
            ))}
          </ol>
        )}
      </div>

      <p className="auth-links">
        <Link to="/projects">Back to projects</Link>
      </p>
    </section>
  )
}
