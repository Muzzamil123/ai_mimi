import { apiClient } from './client'

export type PromptStatus = 'generating' | 'draft' | 'approved' | 'failed' | 'superseded'

export interface Prompt {
  id: number
  video_id: number
  version: number
  content: string | null
  source_idea: string | null
  provider: string | null
  provider_model: string | null
  status: PromptStatus
  input_tokens: number | null
  output_tokens: number | null
  estimated_cost: number | null
  created_by_type: string | null
  created_by_id: number | null
  failure_reason: string | null
  active: boolean
  created_at: string
  updated_at: string
}

export interface PromptListMeta {
  page: number
  per_page: number
  total_count: number
  total_pages: number
}

export interface PromptListResponse {
  prompts: Prompt[]
  meta: PromptListMeta
}

function base(projectId: number, videoId: number): string {
  return `/projects/${projectId}/videos/${videoId}/prompts`
}

export async function listPrompts(
  projectId: number,
  videoId: number,
  params: { page?: number; per_page?: number } = {},
): Promise<PromptListResponse> {
  const { data } = await apiClient.get<PromptListResponse>(base(projectId, videoId), { params })
  return data
}

/** Starts async AI generation of a new prompt version (initial or regenerate). */
export async function generatePrompt(projectId: number, videoId: number): Promise<Prompt> {
  const { data } = await apiClient.post<Prompt>(`${base(projectId, videoId)}/generate`)
  return data
}

/** Saves a manually edited prompt as a new draft version. */
export async function savePromptVersion(
  projectId: number,
  videoId: number,
  content: string,
): Promise<Prompt> {
  const { data } = await apiClient.post<Prompt>(base(projectId, videoId), {
    prompt: { content },
  })
  return data
}

export async function approvePrompt(
  projectId: number,
  videoId: number,
  promptId: number,
): Promise<Prompt> {
  const { data } = await apiClient.post<Prompt>(
    `${base(projectId, videoId)}/${promptId}/approve`,
  )
  return data
}
