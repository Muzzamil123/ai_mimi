import { apiClient } from './client'

export type VideoStatus =
  | 'draft'
  | 'transcribing'
  | 'idea_ready'
  | 'generating_prompt'
  | 'prompt_ready'
  | 'queued'
  | 'generating'
  | 'partially_completed'
  | 'completed'
  | 'failed'
  | 'cancelled'

export interface VideoStatusChange {
  id: number
  from_status: string | null
  to_status: string
  reason: string | null
  actor_id: number | null
  created_at: string
}

export interface Video {
  id: number
  project_id: number
  title: string
  idea_text: string | null
  transcript: string | null
  language: string
  tone: string | null
  duration_seconds: number
  status: VideoStatus
  active_prompt_id: number | null
  has_audio: boolean
  idea_present: boolean
  transcription_failure_reason: string | null
  created_at: string
  updated_at: string
}

/** A single video plus its status-change history (GET .../videos/:id). */
export interface VideoDetail extends Video {
  status_changes: VideoStatusChange[]
}

export interface VideoListMeta {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

export interface VideoListResponse {
  videos: Video[]
  meta: VideoListMeta
}

export interface VideoListParams {
  page?: number
  per_page?: number
  q?: string
  status?: VideoStatus | ''
}

/** Fields a user may set when creating or editing a video's idea. */
export interface VideoInput {
  title?: string
  idea_text?: string | null
  transcript?: string | null
  language?: string
  tone?: string | null
}

export async function listVideos(
  projectId: number,
  params: VideoListParams = {},
): Promise<VideoListResponse> {
  const query: Record<string, string | number> = {}
  if (params.page) query.page = params.page
  if (params.per_page) query.per_page = params.per_page
  if (params.q) query.q = params.q
  if (params.status) query.status = params.status
  const { data } = await apiClient.get<VideoListResponse>(`/projects/${projectId}/videos`, {
    params: query,
  })
  return data
}

export async function getVideo(projectId: number, videoId: number): Promise<VideoDetail> {
  const { data } = await apiClient.get<VideoDetail>(`/projects/${projectId}/videos/${videoId}`)
  return data
}

export async function createVideo(projectId: number, input: VideoInput): Promise<Video> {
  const { data } = await apiClient.post<Video>(`/projects/${projectId}/videos`, { video: input })
  return data
}

export async function updateVideo(
  projectId: number,
  videoId: number,
  input: VideoInput,
): Promise<VideoDetail> {
  const { data } = await apiClient.patch<VideoDetail>(
    `/projects/${projectId}/videos/${videoId}`,
    { video: input },
  )
  return data
}

export async function deleteVideo(projectId: number, videoId: number): Promise<void> {
  await apiClient.delete(`/projects/${projectId}/videos/${videoId}`)
}

/**
 * Uploads a recorded/selected audio idea for transcription. Sends multipart form
 * data; the API responds 202 and transcribes asynchronously.
 */
export async function uploadVideoAudio(
  projectId: number,
  videoId: number,
  audio: Blob,
  filename = 'idea-audio.webm',
): Promise<VideoDetail> {
  const form = new FormData()
  form.append('audio', audio, filename)
  const { data } = await apiClient.post<VideoDetail>(
    `/projects/${projectId}/videos/${videoId}/audio`,
    form,
    { headers: { 'Content-Type': 'multipart/form-data' } },
  )
  return data
}
