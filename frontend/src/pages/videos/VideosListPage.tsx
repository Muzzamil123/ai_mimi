import { useCallback, useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { getProject, type ProjectDetail } from '../../api/projects'
import { listVideos, type Video, type VideoListMeta } from '../../api/videos'
import { EmptyState } from '../../components/EmptyState'
import { Loading } from '../../components/Loading'
import { VideoStatusBadge } from '../../components/VideoStatusBadge'
import { getErrorMessage } from '../../lib/errors'
import { formatVideoLanguage } from './options'

type LoadState =
  | { kind: 'loading' }
  | { kind: 'ready'; videos: Video[]; meta: VideoListMeta }
  | { kind: 'not-ready'; project: ProjectDetail }
  | { kind: 'error'; message: string }

const PER_PAGE = 10

export function VideosListPage() {
  const { id } = useParams<{ id: string }>()
  const projectId = Number(id)
  const navigate = useNavigate()
  const [state, setState] = useState<LoadState>({ kind: 'loading' })
  const [searchInput, setSearchInput] = useState('')
  const [query, setQuery] = useState('')
  const [page, setPage] = useState(1)

  const load = useCallback(async () => {
    setState({ kind: 'loading' })
    try {
      // A video may only exist once the project is ready (character approved).
      const project = await getProject(projectId)
      if (project.status !== 'ready') {
        setState({ kind: 'not-ready', project })
        return
      }
      const { videos, meta } = await listVideos(projectId, { page, per_page: PER_PAGE, q: query })
      setState({ kind: 'ready', videos, meta })
    } catch (err) {
      setState({ kind: 'error', message: getErrorMessage(err, 'Failed to load videos') })
    }
  }, [projectId, page, query])

  useEffect(() => {
    void load()
  }, [load])

  const onSearchSubmit = (event: React.FormEvent) => {
    event.preventDefault()
    setPage(1)
    setQuery(searchInput.trim())
  }

  if (state.kind === 'loading') return <Loading label="Loading videos…" />

  if (state.kind === 'error') {
    return (
      <EmptyState
        title="Unable to load videos"
        description={state.message}
        action={
          <button type="button" onClick={() => void load()}>
            Retry
          </button>
        }
      />
    )
  }

  if (state.kind === 'not-ready') {
    return (
      <EmptyState
        title="Character approval required"
        description="You can add videos once this project's character has been generated and approved."
        action={<Link to={`/projects/${projectId}/character`}>Manage character</Link>}
      />
    )
  }

  return (
    <section className="videos-list">
      <div className="page-header">
        <h1>Videos</h1>
        <button type="button" onClick={() => navigate(`/projects/${projectId}/videos/new`)}>
          New video
        </button>
      </div>

      <form className="projects-filters" onSubmit={onSearchSubmit}>
        <div className="field">
          <label htmlFor="video-search">Search</label>
          <input
            id="video-search"
            type="search"
            placeholder="Search by title or idea…"
            value={searchInput}
            onChange={(event) => setSearchInput(event.target.value)}
          />
        </div>
        <button type="submit">Search</button>
      </form>

      {state.videos.length === 0 ? (
        <EmptyState
          title="No videos yet"
          description="Create your first video and give it an idea by typing or speaking."
          action={
            <button type="button" onClick={() => navigate(`/projects/${projectId}/videos/new`)}>
              New video
            </button>
          }
        />
      ) : (
        <>
          <div className="table-scroll">
            <table className="data-table">
              <thead>
                <tr>
                  <th>Title</th>
                  <th>Language</th>
                  <th>Status</th>
                  <th>Updated</th>
                </tr>
              </thead>
              <tbody>
                {state.videos.map((video) => (
                  <tr key={video.id}>
                    <td>
                      <Link to={`/projects/${projectId}/videos/${video.id}`}>{video.title}</Link>
                    </td>
                    <td>{formatVideoLanguage(video.language)}</td>
                    <td>
                      <VideoStatusBadge status={video.status} />
                    </td>
                    <td>{new Date(video.updated_at).toLocaleDateString()}</td>
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

      <p className="auth-links">
        <Link to={`/projects/${projectId}`}>Back to project</Link>
      </p>
    </section>
  )
}
