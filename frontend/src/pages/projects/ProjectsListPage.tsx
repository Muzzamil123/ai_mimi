import { useCallback, useEffect, useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import {
  listProjects,
  type Project,
  type ProjectListMeta,
  type ProjectStatus,
} from '../../api/projects'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { ProjectStatusBadge } from '../../components/ProjectStatusBadge'
import { getErrorMessage } from '../../lib/errors'
import { STATUS_FILTER_OPTIONS } from './options'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; projects: Project[]; meta: ProjectListMeta }
  | { kind: 'error'; message: string }

const PER_PAGE = 10

export function ProjectsListPage() {
  const navigate = useNavigate()
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  // Draft input value for the search box, applied on submit.
  const [searchInput, setSearchInput] = useState('')
  const [query, setQuery] = useState('')
  const [statusFilter, setStatusFilter] = useState<ProjectStatus | ''>('')
  const [page, setPage] = useState(1)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      const { projects, meta } = await listProjects({
        page,
        per_page: PER_PAGE,
        q: query,
        status: statusFilter,
      })
      setState({ kind: 'ready', projects, meta })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load projects') })
    }
  }, [page, query, statusFilter])

  useEffect(() => {
    void load()
  }, [load])

  const onSearchSubmit = (event: React.FormEvent) => {
    event.preventDefault()
    setPage(1)
    setQuery(searchInput.trim())
  }

  const onStatusChange = (event: React.ChangeEvent<HTMLSelectElement>) => {
    setPage(1)
    setStatusFilter(event.target.value as ProjectStatus | '')
  }

  return (
    <section className="projects-list">
      <div className="page-header">
        <h1>Projects</h1>
        <button type="button" onClick={() => navigate('/projects/new')}>
          New project
        </button>
      </div>

      <form className="projects-filters" onSubmit={onSearchSubmit}>
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
          <select id="project-status" value={statusFilter} onChange={onStatusChange}>
            <option value="">All statuses</option>
            {STATUS_FILTER_OPTIONS.map((option) => (
              <option key={option.value} value={option.value}>
                {option.label}
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
        <EmptyState
          title="No projects yet"
          description="Create your first project to get started."
          action={
            <button type="button" onClick={() => navigate('/projects/new')}>
              New project
            </button>
          }
        />
      )}

      {state.kind === 'ready' && state.projects.length > 0 && (
        <>
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Name</th>
                  <th>Language</th>
                  <th>Status</th>
                  <th>Updated</th>
                </tr>
              </thead>
              <tbody>
                {state.projects.map((project) => (
                  <tr key={project.id}>
                    <td>
                      <Link to={`/projects/${project.id}`}>{project.name}</Link>
                    </td>
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

          <div className="pagination">
            <button
              type="button"
              disabled={state.meta.page <= 1}
              onClick={() => setPage((current) => Math.max(1, current - 1))}
            >
              Previous
            </button>
            <span>
              Page {state.meta.page} of {state.meta.total_pages || 1}
            </span>
            <button
              type="button"
              disabled={state.meta.page >= state.meta.total_pages}
              onClick={() => setPage((current) => current + 1)}
            >
              Next
            </button>
          </div>
        </>
      )}
    </section>
  )
}
