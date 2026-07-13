import { AxiosError, type AxiosResponse } from 'axios'
import { beforeEach, describe, expect, it } from 'vitest'
import {
  clearStoredRefreshToken,
  getStoredRefreshToken,
  normalizeError,
  setStoredRefreshToken,
} from './client'

function makeError(status: number, data: unknown): AxiosError {
  const error = new AxiosError('Request failed')
  error.response = { status, data } as AxiosResponse
  return error
}

describe('normalizeError', () => {
  it('joins the messages array from the error envelope', () => {
    const result = normalizeError(
      makeError(422, { error: { code: 'validation_failed', messages: ['Email is taken', 'Bad'] } }),
    )
    expect(result.status).toBe(422)
    expect(result.message).toBe('Email is taken, Bad')
    expect(result.code).toBe('validation_failed')
  })

  it('falls back to the axios message when there is no response', () => {
    const error = new AxiosError('Network Error')
    const result = normalizeError(error)
    expect(result.status).toBe(0)
    expect(result.message).toBe('Network Error')
  })
})

describe('refresh-token storage helpers', () => {
  beforeEach(() => {
    clearStoredRefreshToken()
  })

  it('stores, reads and clears the refresh token', () => {
    expect(getStoredRefreshToken()).toBeNull()
    setStoredRefreshToken('token-123')
    expect(getStoredRefreshToken()).toBe('token-123')
    clearStoredRefreshToken()
    expect(getStoredRefreshToken()).toBeNull()
  })
})
