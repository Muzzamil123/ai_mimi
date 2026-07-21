import { apiClient } from './client'

// --- Shared value types ------------------------------------------------------

export type ServiceType =
  | 'character_image'
  | 'text_generation'
  | 'speech_to_text'
  | 'video_generation'

export const SERVICE_TYPES: ServiceType[] = [
  'character_image',
  'text_generation',
  'speech_to_text',
  'video_generation',
]

export type BudgetScope = 'global' | 'user' | 'project'
export type BudgetAction = 'warn' | 'block'

function withParams(base: Record<string, string | number | undefined>): Record<string, string | number> {
  const out: Record<string, string | number> = {}
  for (const [key, value] of Object.entries(base)) {
    if (value !== undefined && value !== '' && value !== null) out[key] = value
  }
  return out
}

export interface DateRangeParams {
  from?: string
  to?: string
}

// --- Cost dashboard ----------------------------------------------------------

export interface CostGroupRow {
  key: string | null
  estimated_cost: number
  count: number
}

export interface CostDayRow {
  day: string
  estimated_cost: number
}

export interface CostReport {
  range: { from: string; to: string }
  totals: { estimated_cost: number; count: number; unpriced_count: number }
  by_provider: CostGroupRow[]
  by_service: CostGroupRow[]
  by_day: CostDayRow[]
  averages: { per_video: number; per_project: number }
}

export async function getCosts(params: DateRangeParams = {}): Promise<CostReport> {
  const { data } = await apiClient.get<CostReport>('/admin/costs', { params: withParams({ ...params }) })
  return data
}

export interface SpendRow {
  id: number
  estimated_cost: number
  count: number
  label: string | null
}

export interface SpendResponse {
  rows: SpendRow[]
}

export async function getUserSpend(params: DateRangeParams & { limit?: number } = {}): Promise<SpendResponse> {
  const { data } = await apiClient.get<SpendResponse>('/admin/costs/users', { params: withParams({ ...params }) })
  return data
}

export async function getProjectSpend(params: DateRangeParams & { limit?: number } = {}): Promise<SpendResponse> {
  const { data } = await apiClient.get<SpendResponse>('/admin/costs/projects', { params: withParams({ ...params }) })
  return data
}

/** Downloads the usage ledger CSV in the browser. */
export async function exportCosts(params: DateRangeParams & { provider?: string } = {}): Promise<void> {
  const response = await apiClient.get('/admin/costs/export', {
    params: withParams({ ...params }),
    responseType: 'blob',
  })
  const url = URL.createObjectURL(response.data as Blob)
  const link = document.createElement('a')
  link.href = url
  link.download = `provider-usage-${params.from ?? 'start'}-to-${params.to ?? 'now'}.csv`
  document.body.appendChild(link)
  link.click()
  link.remove()
  URL.revokeObjectURL(url)
}

// --- Provider pricing --------------------------------------------------------

export interface ProviderPrice {
  id: number
  provider: string
  service_type: ServiceType
  model: string
  currency: string
  enabled: boolean
  per_input_token: string | null
  per_output_token: string | null
  per_image: string | null
  per_second: string | null
  per_request: string | null
  updated_at: string
}

export interface ProviderPriceInput {
  provider: string
  service_type: ServiceType
  model?: string
  currency?: string
  enabled?: boolean
  per_input_token?: string | null
  per_output_token?: string | null
  per_image?: string | null
  per_second?: string | null
  per_request?: string | null
}

export async function listProviderPrices(): Promise<{ provider_prices: ProviderPrice[] }> {
  const { data } = await apiClient.get<{ provider_prices: ProviderPrice[] }>('/admin/provider_prices')
  return data
}

export async function createProviderPrice(input: ProviderPriceInput): Promise<ProviderPrice> {
  const { data } = await apiClient.post<ProviderPrice>('/admin/provider_prices', { provider_price: input })
  return data
}

export async function updateProviderPrice(id: number, input: ProviderPriceInput): Promise<ProviderPrice> {
  const { data } = await apiClient.patch<ProviderPrice>(`/admin/provider_prices/${id}`, { provider_price: input })
  return data
}

export async function deleteProviderPrice(id: number): Promise<void> {
  await apiClient.delete(`/admin/provider_prices/${id}`)
}

// --- Budget policies ---------------------------------------------------------

export interface BudgetPolicy {
  id: number
  scope_type: BudgetScope
  scope_id: number | null
  provider: string | null
  daily_limit: number | null
  monthly_limit: number | null
  warning_percentage: number
  action_on_limit: BudgetAction
  enabled: boolean
  created_at: string
  updated_at: string
}

export interface BudgetPolicyInput {
  scope_type: BudgetScope
  scope_id?: number | null
  provider?: string | null
  daily_limit?: number | null
  monthly_limit?: number | null
  warning_percentage?: number
  action_on_limit?: BudgetAction
  enabled?: boolean
}

export async function listBudgetPolicies(): Promise<{ budget_policies: BudgetPolicy[] }> {
  const { data } = await apiClient.get<{ budget_policies: BudgetPolicy[] }>('/admin/budget_policies')
  return data
}

export async function createBudgetPolicy(input: BudgetPolicyInput): Promise<BudgetPolicy> {
  const { data } = await apiClient.post<BudgetPolicy>('/admin/budget_policies', { budget_policy: input })
  return data
}

export async function updateBudgetPolicy(id: number, input: BudgetPolicyInput): Promise<BudgetPolicy> {
  const { data } = await apiClient.patch<BudgetPolicy>(`/admin/budget_policies/${id}`, { budget_policy: input })
  return data
}

export async function deleteBudgetPolicy(id: number): Promise<void> {
  await apiClient.delete(`/admin/budget_policies/${id}`)
}
