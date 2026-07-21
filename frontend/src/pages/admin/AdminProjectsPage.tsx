import { useCallback, useEffect, useState } from 'react'
import { Link } from 'react-router-dom'
import { listProjects, type AdminListMeta, type AdminProjectListParams } from '../../api/admin'
import type { Project, ProjectStatus } from '../../api/projects'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { Pagination } from '../../components/Pagination'
import { ProjectStatusBadge } from '../../components/ProjectStatusBadge'
import { getErrorMessage } from '../../lib/errors'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; projects: Project[]; meta: AdminListMeta }
  | { kind: 'error'; message: string }

const PER_PAGE = 20

const STATUS_OPTIONS: ProjectStatus[] = [
  'draft',
  'initializing_character',
  'awaiting_character_approval',
  'character_rejected',
  'ready',
  'failed',
  'archived',
]

export function AdminProjectsPage() {
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [searchInput, setSearchInput] = useState('')
  const [query, setQuery] = useState('')
  const [status, setStatus] = useState<ProjectStatus | ''>('')
  const [page, setPage] = useState(1)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const params: AdminProjectListParams = { page, per_page: PER_PAGE, q: query, status }
      const { projects, meta } = await listProjects(params)
      setState({ kind: 'ready', projects, meta })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load projects') })
    }
  }, [page, query, status])

  useEffect(() => {
    void load()
  }, [load])

  const onSearchSubmit = (event: React.FormEvent) => {
    event.preventDefault()
    setPage(1)
    setQuery(searchInput.trim())
  }

  return (
    <section className="admin-projects">
      <div className="page-header">
        <h1>Projects</h1>
      </div>

      <form className="admin-filters" onSubmit={onSearchSubmit}>
        <div className="field">
          <label htmlFor="project-search">Search</label>
          <input
            id="project-search"
            type="search"
            placeholder="Search by name…"
            value={searchInput}
            onChange={(event) => setSearchInput(event.target.value)}
          />
        </div>
        <div className="field">
          <label htmlFor="project-status">Status</label>
          <select
            id="project-status"
            value={status}
            onChange={(event) => {
              setPage(1)
              setStatus(event.target.value as ProjectStatus | '')
            }}
          >
            <option value="">All statuses</option>
            {STATUS_OPTIONS.map((option) => (
              <option key={option} value={option}>
                {option}
              </option>
            ))}
          </select>
        </div>
        <button type="submit">Search</button>
      </form>

      {state.kind === 'loading' && <Loading label="Loading projects…" />}

      {state.kind === 'error' && (
        <EmptyState
          title="Unable to load projects"
          description={state.message}
          action={
            <button type="button" onClick={() => void load()}>
              Retry
            </button>
          }
        />
      )}

      {state.kind === 'ready' && state.projects.length === 0 && (
        <EmptyState title="No projects" description="No projects match these filters." />
      )}

      {state.kind === 'ready' && state.projects.length > 0 && (
        <>
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>ID</th>
                  <th>Name</th>
                  <th>Owner</th>
                  <th>Language</th>
                  <th>Status</th>
                  <th>Updated</th>
                </tr>
              </thead>
              <tbody>
                {state.projects.map((project) => (
                  <tr key={project.id}>
                    <td>{project.id}</td>
                    <td>
                      <Link to={`/admin/projects/${project.id}`}>{project.name}</Link>
                    </td>
                    <td>#{project.user_id}</td>
                    <td>{project.default_language}</td>
                    <td>
                      <ProjectStatusBadge status={project.status} />
                    </td>
                    <td>{new Date(project.updated_at).toLocaleDateString()}</td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
          <Pagination meta={state.meta} onPageChange={setPage} />
        </>
      )}
    </section>
  )
}
