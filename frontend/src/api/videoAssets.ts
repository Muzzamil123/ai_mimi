import { apiClient } from './client'
import { env } from '../config/env'

export type ValidationStatus = 'pending' | 'valid' | 'invalid' | 'failed'

export interface VideoAsset {
  id: number
  video_generation_id: number
  filename: string | null
  mime_type: string | null
  width: number | null
  height: number | null
  duration_seconds: number | null
  file_size: number | null
  validation_status: ValidationStatus
  aspect_ratio: string
  variation_number: number
  ready: boolean
  duplicate: boolean
  stream_url: string | null
  download_url: string | null
  thumbnail_url: string | null
  created_at: string
}

export interface VideoAssetListResponse {
  video_assets: VideoAsset[]
}

/**
 * Resolves a relative signed download path (e.g. "/api/v1/downloads?token=…")
 * to an absolute URL against the API origin, so it works in <video>/<img>/<a>
 * regardless of the frontend origin.
 */
export function resolveDownloadUrl(path: string | null): string | null {
  if (!path) return null
  try {
    return new URL(path, env.apiBaseUrl).toString()
  } catch {
    return path
  }
}

export async function listVideoAssets(
  projectId: number,
  videoId: number,
): Promise<VideoAssetListResponse> {
  const { data } = await apiClient.get<VideoAssetListResponse>(
    `/projects/${projectId}/videos/${videoId}/assets`,
  )
  return data
}

/** Downloads all of a video's outputs as a single ZIP (authenticated blob). */
export async function downloadAllOutputs(projectId: number, videoId: number): Promise<void> {
  const res = await apiClient.get(`/projects/${projectId}/videos/${videoId}/assets/archive`, {
    responseType: 'blob',
  })
  triggerBlobDownload(res.data as Blob, `video-${videoId}-outputs.zip`)
}

function triggerBlobDownload(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob)
  const link = document.createElement('a')
  link.href = url
  link.download = filename
  document.body.appendChild(link)
  link.click()
  link.remove()
  URL.revokeObjectURL(url)
}
