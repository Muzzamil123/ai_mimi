import { apiClient } from './client'

export type CharacterStatus =
  | 'pending'
  | 'generating'
  | 'awaiting_approval'
  | 'rejected'
  | 'approved'
  | 'failed'

export interface CharacterImage {
  id: number
  character_id: number
  mime_type: string
  width: number | null
  height: number | null
  file_size: number | null
  checksum: string | null
  provider_asset_id: string | null
  created_at: string
}

export interface Character {
  id: number
  project_id: number
  name: string
  description: string | null
  attributes: Record<string, string>
  style_preferences: Record<string, string>
  status: CharacterStatus
  provider: string | null
  provider_model: string | null
  generation_prompt: string | null
  failure_reason: string | null
  rejection_feedback: string | null
  locked: boolean
  estimated_cost: number | null
  image_url: string | null
  latest_image: CharacterImage | null
  approved_at: string | null
  rejected_at: string | null
  locked_at: string | null
  created_at: string
  updated_at: string
}

export interface CharacterInput {
  name: string
  description?: string
  attributes?: Record<string, string>
  style_preferences?: Record<string, string>
}

/** Status codes returned when a project has no character yet. */
export const NO_CHARACTER_STATUS = 404

export async function getCharacter(projectId: number): Promise<Character> {
  const { data } = await apiClient.get<Character>(`/projects/${projectId}/character`)
  return data
}

export async function createCharacter(
  projectId: number,
  input: CharacterInput,
): Promise<Character> {
  const { data } = await apiClient.post<Character>(`/projects/${projectId}/character`, {
    character: input,
  })
  return data
}

export async function updateCharacter(
  projectId: number,
  input: CharacterInput,
): Promise<Character> {
  const { data } = await apiClient.patch<Character>(`/projects/${projectId}/character`, {
    character: input,
  })
  return data
}

export async function deleteCharacter(projectId: number): Promise<void> {
  await apiClient.delete(`/projects/${projectId}/character`)
}

export async function generateCharacter(projectId: number): Promise<Character> {
  const { data } = await apiClient.post<Character>(`/projects/${projectId}/character/generate`)
  return data
}

export async function approveCharacter(projectId: number): Promise<Character> {
  const { data } = await apiClient.post<Character>(`/projects/${projectId}/character/approve`)
  return data
}

export async function rejectCharacter(
  projectId: number,
  feedback?: string,
): Promise<Character> {
  const { data } = await apiClient.post<Character>(`/projects/${projectId}/character/reject`, {
    feedback,
  })
  return data
}

export async function resetCharacter(projectId: number): Promise<Character> {
  const { data } = await apiClient.post<Character>(`/projects/${projectId}/character/reset`)
  return data
}

/**
 * Fetches the character image through the authenticated endpoint and returns a
 * blob object URL. Callers must revoke the URL when done.
 */
export async function fetchCharacterImageUrl(projectId: number): Promise<string> {
  const res = await apiClient.get(`/projects/${projectId}/character/image`, {
    responseType: 'blob',
  })
  return URL.createObjectURL(res.data as Blob)
}
