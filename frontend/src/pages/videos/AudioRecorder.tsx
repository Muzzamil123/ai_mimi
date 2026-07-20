import { useEffect, useRef, useState } from 'react'

interface AudioRecorderProps {
  disabled?: boolean
  /** Called with the recorded audio when the user confirms the take. */
  onRecorded: (audio: Blob, filename: string) => void
}

type RecorderState = 'idle' | 'recording' | 'recorded'

/** True when the browser supports in-page audio recording. */
function recordingSupported(): boolean {
  return (
    typeof navigator !== 'undefined' &&
    !!navigator.mediaDevices &&
    typeof navigator.mediaDevices.getUserMedia === 'function' &&
    typeof window !== 'undefined' &&
    'MediaRecorder' in window
  )
}

/**
 * Browser microphone recorder for a spoken video idea. Falls back to a file
 * picker when the MediaRecorder API is unavailable (e.g. insecure context or
 * unsupported browser), so a user can always provide audio.
 */
export function AudioRecorder({ disabled = false, onRecorded }: AudioRecorderProps) {
  const [supported] = useState(recordingSupported)
  const [state, setState] = useState<RecorderState>('idle')
  const [error, setError] = useState<string | null>(null)
  const [previewUrl, setPreviewUrl] = useState<string | null>(null)

  const recorderRef = useRef<MediaRecorder | null>(null)
  const chunksRef = useRef<Blob[]>([])
  const streamRef = useRef<MediaStream | null>(null)
  const blobRef = useRef<Blob | null>(null)

  // Release the mic and any object URL when the component unmounts.
  useEffect(() => {
    return () => {
      streamRef.current?.getTracks().forEach((track) => track.stop())
      if (previewUrl) URL.revokeObjectURL(previewUrl)
    }
  }, [previewUrl])

  const start = async () => {
    setError(null)
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      streamRef.current = stream
      chunksRef.current = []
      const recorder = new MediaRecorder(stream)
      recorder.ondataavailable = (event) => {
        if (event.data.size > 0) chunksRef.current.push(event.data)
      }
      recorder.onstop = () => {
        const blob = new Blob(chunksRef.current, { type: recorder.mimeType || 'audio/webm' })
        blobRef.current = blob
        if (previewUrl) URL.revokeObjectURL(previewUrl)
        setPreviewUrl(URL.createObjectURL(blob))
        setState('recorded')
        streamRef.current?.getTracks().forEach((track) => track.stop())
        streamRef.current = null
      }
      recorderRef.current = recorder
      recorder.start()
      setState('recording')
    } catch {
      setError('Could not access the microphone. Check permissions or upload a file instead.')
    }
  }

  const stop = () => {
    recorderRef.current?.stop()
  }

  const confirm = () => {
    if (blobRef.current) {
      const extension = (blobRef.current.type.split('/')[1] || 'webm').split(';')[0]
      onRecorded(blobRef.current, `idea-audio.${extension}`)
    }
  }

  const discard = () => {
    blobRef.current = null
    if (previewUrl) URL.revokeObjectURL(previewUrl)
    setPreviewUrl(null)
    setState('idle')
  }

  const onFilePicked = (event: React.ChangeEvent<HTMLInputElement>) => {
    const file = event.target.files?.[0]
    if (file) onRecorded(file, file.name)
  }

  if (!supported) {
    return (
      <div className="audio-recorder">
        <p className="muted">Recording isn&apos;t supported here. Upload an audio file instead:</p>
        <input type="file" accept="audio/*" disabled={disabled} onChange={onFilePicked} />
      </div>
    )
  }

  return (
    <div className="audio-recorder">
      {error && <p className="field-error">{error}</p>}

      {state === 'idle' && (
        <button type="button" disabled={disabled} onClick={() => void start()}>
          Record idea
        </button>
      )}

      {state === 'recording' && (
        <div className="audio-recorder__recording" role="status">
          <span className="recording-dot" aria-hidden="true" /> Recording…
          <button type="button" onClick={stop}>
            Stop
          </button>
        </div>
      )}

      {state === 'recorded' && (
        <div className="audio-recorder__review">
          {previewUrl && <audio controls src={previewUrl} />}
          <div className="character-actions">
            <button type="button" disabled={disabled} onClick={confirm}>
              Use this recording
            </button>
            <button type="button" disabled={disabled} onClick={discard}>
              Re-record
            </button>
          </div>
        </div>
      )}

      <div className="audio-recorder__upload">
        <label htmlFor="audio-file" className="muted">
          …or upload a file
        </label>
        <input id="audio-file" type="file" accept="audio/*" disabled={disabled} onChange={onFilePicked} />
      </div>
    </div>
  )
}
