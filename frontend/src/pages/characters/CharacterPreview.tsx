import { useEffect, useState } from 'react'
import { fetchCharacterImageUrl, type Character } from '../../api/characters'

/** Renders the generated character image (fetched through the authed endpoint). */
export function CharacterPreview({
  projectId,
  character,
}: {
  projectId: number
  character: Character
}) {
  const [imageUrl, setImageUrl] = useState<string | null>(null)
  const [failed, setFailed] = useState(false)
  const imageId = character.latest_image?.id

  useEffect(() => {
    if (!character.image_url) return
    let objectUrl: string | null = null
    let active = true

    void (async () => {
      try {
        const url = await fetchCharacterImageUrl(projectId)
        if (!active) {
          URL.revokeObjectURL(url)
          return
        }
        objectUrl = url
        setImageUrl(url)
      } catch {
        if (active) setFailed(true)
      }
    })()

    return () => {
      active = false
      if (objectUrl) URL.revokeObjectURL(objectUrl)
    }
    // Re-fetch whenever a new image is generated.
  }, [projectId, imageId, character.image_url])

  if (!character.image_url) {
    return <p className="muted">No image generated yet.</p>
  }

  if (failed) {
    return <p className="field-error">Unable to load the character image.</p>
  }

  return (
    <figure className="character-preview">
      {imageUrl ? (
        <img src={imageUrl} alt={`Character ${character.name}`} className="character-preview__image" />
      ) : (
        <p className="muted">Loading image…</p>
      )}
      <figcaption className="character-preview__meta">
        {character.latest_image?.width && character.latest_image?.height
          ? `${character.latest_image.width}×${character.latest_image.height}`
          : null}
        {character.provider ? ` · ${character.provider}` : null}
      </figcaption>
    </figure>
  )
}
