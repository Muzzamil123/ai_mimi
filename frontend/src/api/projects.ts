import { apiClient } from './client'

export type ProjectStatus =
  | 'draft'
  | 'initializing_character'
  | 'awaiting_character_approval'
  | 'character_rejected'
  | 'ready'
  | 'failed'
  | 'archived'

export type ProjectLanguage = 'english' | 'urdu' | 'roman_urdu' | 'punjabi'

export type ProjectPlatform = 'instagram_reels' | 'tiktok' | 'youtube_shorts' | 'other'

export interface Project {
  id: number
  user_id: number
  name: string
  slug: string
  description: string | null
  default_language: string
  default_tone: string
  target_platforms: string[]
  status: ProjectStatus
  active_character_id: number | null
  archived_at: string | null
  created_at: string
  updated_at: string
}

export interface ProjectStatusChange {
  id: number
  from_status: string | null
  to_status: string
  reason: string | null
  actor_id: number | null
  created_at: string
}

/** A single project plus its status-change history (GET /projects/:id). */
export interface ProjectDetail extends Project {
  status_changes: ProjectStatusChange[]
}

export interface ProjectListMeta {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

export interface ProjectListResponse {
  projects: Project[]
  meta: ProjectListMeta
}

export interface ProjectListParams {
  page?: number
  per_page?: number
  q?: string
  status?: ProjectStatus | ''
}

export interface ProjectInput {
  name: string
  description?: string
  default_language?: string
  default_tone?: string
  target_platforms?: string[]
}

export async function listProjects(params: ProjectListParams = {}): Promise<ProjectListResponse> {
  const query: Record<string, string | number> = {}
  if (params.page) query.page = params.page
  if (params.per_page) query.per_page = params.per_page
  if (params.q) query.q = params.q
  if (params.status) query.status = params.status
  const { data } = await apiClient.get<ProjectListResponse>('/projects', { params: query })
  return data
}

export async function getProject(id: number): Promise<ProjectDetail> {
  const { data } = await apiClient.get<ProjectDetail>(`/projects/${id}`)
  return data
}

export async function createProject(input: ProjectInput): Promise<Project> {
  const { data } = await apiClient.post<Project>('/projects', { project: input })
  return data
}

export async function updateProject(id: number, input: ProjectInput): Promise<Project> {
  const { data } = await apiClient.patch<Project>(`/projects/${id}`, { project: input })
  return data
}

export async function deleteProject(id: number): Promise<void> {
  await apiClient.delete(`/projects/${id}`)
}

export async function archiveProject(id: number): Promise<Project> {
  const { data } = await apiClient.post<Project>(`/projects/${id}/archive`)
  return data
}

export async function restoreProject(id: number): Promise<Project> {
  const { data } = await apiClient.post<Project>(`/projects/${id}/restore`)
  return data
}
