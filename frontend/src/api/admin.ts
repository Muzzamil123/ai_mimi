import type { UserRole, UserStatus } from './auth'
import type { Character } from './characters'
import { apiClient } from './client'
import type { Project, ProjectStatus, ProjectStatusChange } from './projects'
import type { Prompt } from './prompts'
import type { Video, VideoStatus, VideoStatusChange } from './videos'
import type { VideoGeneration, VideoGenerationStatus } from './videoGenerations'

/** Offset-pagination metadata returned by every admin list endpoint. */
export interface AdminListMeta {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

interface ListParams {
  page?: number
  per_page?: number
}

function withParams(base: Record<string, string | number | undefined>): Record<string, string | number> {
  const out: Record<string, string | number> = {}
  for (const [key, value] of Object.entries(base)) {
    if (value !== undefined && value !== '' && value !== null) out[key] = value
  }
  return out
}

// --- Dashboard & health ------------------------------------------------------

export type StatusCounts = Record<string, number>

export interface HealthReport {
  status: string
  version: string
  components: Record<string, string>
  timestamp: string
}

export interface DashboardData {
  users: StatusCounts
  projects: StatusCounts
  videos: StatusCounts
  generations: StatusCounts
  assets: StatusCounts
  email_deliveries: StatusCounts
  totals: {
    users: number
    projects: number
    videos: number
    generations: number
    failed_generations: number
    audit_logs: number
  }
  health: HealthReport
}

export async function getDashboard(): Promise<DashboardData> {
  const { data } = await apiClient.get<DashboardData>('/admin/dashboard')
  return data
}

export async function getHealth(): Promise<HealthReport> {
  const { data } = await apiClient.get<HealthReport>('/admin/health')
  return data
}

// --- Usage -------------------------------------------------------------------

export interface UsageProviderRow {
  provider: string | null
  count: number
  estimated_cost: number
  input_tokens?: number
  output_tokens?: number
}

export interface UsageServiceSummary {
  service_type: string
  total_count: number
  total_estimated_cost: number
  providers: UsageProviderRow[]
}

export interface UsageData {
  character_generation: UsageServiceSummary
  prompt_generation: UsageServiceSummary
  video_generation: UsageServiceSummary
  note: string
}

export async function getUsage(): Promise<UsageData> {
  const { data } = await apiClient.get<UsageData>('/admin/usage')
  return data
}

// --- Settings ----------------------------------------------------------------

export type SettingType = 'string' | 'integer' | 'boolean'

export interface SettingRow {
  key: string
  type: SettingType
  secret: boolean
  description: string
  configured: boolean
  value: string | number | boolean | null
}

export interface SettingsResponse {
  settings: SettingRow[]
}

export async function getSettings(): Promise<SettingsResponse> {
  const { data } = await apiClient.get<SettingsResponse>('/admin/settings')
  return data
}

export async function updateSettings(
  changes: Record<string, string | number | boolean>,
): Promise<SettingsResponse> {
  const { data } = await apiClient.patch<SettingsResponse>('/admin/settings', { settings: changes })
  return data
}

// --- Users -------------------------------------------------------------------

export interface AdminUser {
  id: number
  name: string
  email: string
  role: UserRole
  status: UserStatus
  email_verified: boolean
  projects_count: number
  last_login_at: string | null
  created_at: string
  updated_at: string
}

export interface AdminUserListParams extends ListParams {
  q?: string
  role?: UserRole | ''
  status?: UserStatus | ''
}

export interface AdminUserListResponse {
  users: AdminUser[]
  meta: AdminListMeta
}

export async function listUsers(params: AdminUserListParams = {}): Promise<AdminUserListResponse> {
  const { data } = await apiClient.get<AdminUserListResponse>('/admin/users', {
    params: withParams({ ...params }),
  })
  return data
}

export async function suspendUser(id: number, reason?: string): Promise<AdminUser> {
  const { data } = await apiClient.post<AdminUser>(`/admin/users/${id}/suspend`, { reason })
  return data
}

export async function reactivateUser(id: number): Promise<AdminUser> {
  const { data } = await apiClient.post<AdminUser>(`/admin/users/${id}/reactivate`)
  return data
}

// --- Projects ----------------------------------------------------------------

export interface AdminProjectListParams extends ListParams {
  q?: string
  status?: ProjectStatus | ''
  user_id?: number
}

export interface AdminProjectListResponse {
  projects: Project[]
  meta: AdminListMeta
}

export interface AdminProjectDetail {
  project: Project & { status_changes: ProjectStatusChange[] }
  owner: AdminUser
  character: Character | null
  videos: Video[]
  generations: VideoGeneration[]
}

export async function listProjects(
  params: AdminProjectListParams = {},
): Promise<AdminProjectListResponse> {
  const { data } = await apiClient.get<AdminProjectListResponse>('/admin/projects', {
    params: withParams({ ...params }),
  })
  return data
}

export async function getProject(id: number): Promise<AdminProjectDetail> {
  const { data } = await apiClient.get<AdminProjectDetail>(`/admin/projects/${id}`)
  return data
}

export async function archiveProject(id: number): Promise<Project> {
  const { data } = await apiClient.post<Project>(`/admin/projects/${id}/archive`)
  return data
}

export async function resetCharacter(id: number, reason?: string): Promise<Character> {
  const { data } = await apiClient.post<Character>(`/admin/projects/${id}/reset_character`, { reason })
  return data
}

export async function retryCharacter(id: number): Promise<Character> {
  const { data } = await apiClient.post<Character>(`/admin/projects/${id}/retry_character`)
  return data
}

// --- Videos ------------------------------------------------------------------

export interface AdminVideoListParams extends ListParams {
  q?: string
  status?: VideoStatus | ''
  project_id?: number
}

export interface AdminVideoListResponse {
  videos: Video[]
  meta: AdminListMeta
}

export interface AdminVideoDetail {
  video: Video & { status_changes: VideoStatusChange[] }
  prompts: Prompt[]
  generations: VideoGeneration[]
}

export async function listVideos(params: AdminVideoListParams = {}): Promise<AdminVideoListResponse> {
  const { data } = await apiClient.get<AdminVideoListResponse>('/admin/videos', {
    params: withParams({ ...params }),
  })
  return data
}

export async function getVideo(id: number): Promise<AdminVideoDetail> {
  const { data } = await apiClient.get<AdminVideoDetail>(`/admin/videos/${id}`)
  return data
}

export async function retryPrompt(id: number): Promise<Video> {
  const { data } = await apiClient.post<Video>(`/admin/videos/${id}/retry_prompt`)
  return data
}

// --- Video generations -------------------------------------------------------

export interface AdminGenerationListParams extends ListParams {
  status?: VideoGenerationStatus | ''
  project_id?: number
  video_id?: number
}

export interface AdminGenerationListResponse {
  generations: VideoGeneration[]
  meta: AdminListMeta
}

export async function listGenerations(
  params: AdminGenerationListParams = {},
): Promise<AdminGenerationListResponse> {
  const { data } = await apiClient.get<AdminGenerationListResponse>('/admin/video_generations', {
    params: withParams({ ...params }),
  })
  return data
}

export async function retryGeneration(id: number): Promise<VideoGeneration> {
  const { data } = await apiClient.post<VideoGeneration>(`/admin/video_generations/${id}/retry`)
  return data
}

export async function retryGenerationAsset(id: number): Promise<VideoGeneration> {
  const { data } = await apiClient.post<VideoGeneration>(`/admin/video_generations/${id}/retry_asset`)
  return data
}

export async function cancelGeneration(id: number): Promise<VideoGeneration> {
  const { data } = await apiClient.post<VideoGeneration>(`/admin/video_generations/${id}/cancel`)
  return data
}

// --- Email deliveries --------------------------------------------------------

export type EmailDeliveryStatus = 'queued' | 'sent' | 'delivered' | 'failed' | 'bounced'

export interface AdminEmailDelivery {
  id: number
  user_id: number | null
  project_id: number | null
  video_id: number | null
  email_type: string
  recipient: string
  subject: string | null
  provider: string | null
  provider_message_id: string | null
  status: EmailDeliveryStatus
  error_message: string | null
  sent_at: string | null
  delivered_at: string | null
  created_at: string
}

export interface AdminEmailListParams extends ListParams {
  status?: EmailDeliveryStatus | ''
  email_type?: string
  user_id?: number
}

export interface AdminEmailListResponse {
  email_deliveries: AdminEmailDelivery[]
  meta: AdminListMeta
}

export async function listEmailDeliveries(
  params: AdminEmailListParams = {},
): Promise<AdminEmailListResponse> {
  const { data } = await apiClient.get<AdminEmailListResponse>('/admin/email_deliveries', {
    params: withParams({ ...params }),
  })
  return data
}

export async function retryEmailDelivery(id: number): Promise<void> {
  await apiClient.post(`/admin/email_deliveries/${id}/retry`)
}

// --- Audit logs --------------------------------------------------------------

export interface AuditLogEntry {
  id: number
  action: string
  resource_type: string | null
  resource_id: number | null
  metadata: Record<string, unknown>
  ip_address: string | null
  user_agent: string | null
  actor_type: string | null
  actor_id: number | null
  actor_label: string | null
  created_at: string
}

export interface AuditLogListParams extends ListParams {
  action_name?: string
  actor_id?: number
  resource_type?: string
  resource_id?: number
}

export interface AuditLogListResponse {
  audit_logs: AuditLogEntry[]
  meta: AdminListMeta
}

export async function listAuditLogs(
  params: AuditLogListParams = {},
): Promise<AuditLogListResponse> {
  const { data } = await apiClient.get<AuditLogListResponse>('/admin/audit_logs', {
    params: withParams({ ...params }),
  })
  return data
}
