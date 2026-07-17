import { env } from '../config/env'
import { apiClient } from './client'

export type ApprovalStatus = 'pending' | 'approved' | 'rejected' | 'expired' | 'cancelled'

export interface ApprovalRequest {
  id: number
  status: ApprovalStatus
  actionable: boolean
  feedback: string | null
  expires_at: string | null
  responded_at: string | null
  project: { name: string }
  character: { name: string; description: string | null; has_image: boolean }
}

/**
 * Public, token-protected character-approval calls. These endpoints require no
 * authentication — possession of the single-use token is the authorization.
 */
export async function getApproval(token: string): Promise<ApprovalRequest> {
  const { data } = await apiClient.get<ApprovalRequest>(
    `/approvals/character/${encodeURIComponent(token)}`,
  )
  return data
}

export async function approveViaToken(token: string): Promise<ApprovalRequest> {
  const { data } = await apiClient.post<ApprovalRequest>(
    `/approvals/character/${encodeURIComponent(token)}/approve`,
  )
  return data
}

export async function rejectViaToken(
  token: string,
  feedback?: string,
): Promise<ApprovalRequest> {
  const { data } = await apiClient.post<ApprovalRequest>(
    `/approvals/character/${encodeURIComponent(token)}/reject`,
    { feedback },
  )
  return data
}

/** Absolute URL to the token-gated preview image (usable directly as <img src>). */
export function approvalImageUrl(token: string): string {
  return `${env.apiBaseUrl}/approvals/character/${encodeURIComponent(token)}/image`
}
