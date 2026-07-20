import { apiClient } from './client'

export type VideoGenerationStatus =
  | 'pending'
  | 'processing'
  | 'completed'
  | 'failed'
  | 'cancelled'

export interface VideoGeneration {
  id: number
  video_id: number
  aspect_ratio: string
  variation_number: number
  duration_seconds: number
  status: VideoGenerationStatus
  progress: number
  attempt_count: number
  error_code: string | null
  error_message: string | null
  provider: string | null
  label: string
  estimated_cost: number | null
  started_at: string | null
  completed_at: string | null
  created_at: string
}

export interface VideoGenerationListResponse {
  video_generations: VideoGeneration[]
}

function base(projectId: number, videoId: number): string {
  return `/projects/${projectId}/videos/${videoId}/generations`
}

export async function listVideoGenerations(
  projectId: number,
  videoId: number,
): Promise<VideoGenerationListResponse> {
  const { data } = await apiClient.get<VideoGenerationListResponse>(base(projectId, videoId))
  return data
}

/** Starts the batch (four outputs). Responds 202 with the current batch. */
export async function startVideoGeneration(
  projectId: number,
  videoId: number,
): Promise<VideoGenerationListResponse> {
  const { data } = await apiClient.post<VideoGenerationListResponse>(base(projectId, videoId))
  return data
}

export async function retryVideoGeneration(
  projectId: number,
  videoId: number,
  generationId: number,
): Promise<VideoGeneration> {
  const { data } = await apiClient.post<VideoGeneration>(
    `${base(projectId, videoId)}/${generationId}/retry`,
  )
  return data
}

export async function cancelVideoGeneration(
  projectId: number,
  videoId: number,
): Promise<VideoGenerationListResponse> {
  const { data } = await apiClient.post<VideoGenerationListResponse>(
    `${base(projectId, videoId)}/cancel`,
  )
  return data
}
