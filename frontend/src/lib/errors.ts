/** Extracts a user-facing message from a normalized ApiError or any thrown value. */
export function getErrorMessage(err: unknown, fallback = 'Something went wrong'): string {
  // A normalized ApiError with no HTTP status (status 0) means the request never
  // reached the API — surface an actionable, retry-oriented message.
  if (err && typeof err === 'object' && 'status' in err) {
    const status = (err as { status: unknown }).status
    if (status === 0) {
      return 'Network error — check your connection and retry.'
    }
  }
  if (err && typeof err === 'object' && 'message' in err) {
    const message = (err as { message: unknown }).message
    if (typeof message === 'string' && message.length > 0) {
      return message
    }
  }
  return fallback
}
