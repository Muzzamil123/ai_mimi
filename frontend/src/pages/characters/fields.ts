/**
 * Character attribute and style fields. The backend accepts an arbitrary hash,
 * so these are a curated, extensible set of optional inputs that map into the
 * `attributes` and `style_preferences` objects.
 */
export interface CharacterField {
  key: string
  label: string
  placeholder?: string
}

export const ATTRIBUTE_FIELDS: CharacterField[] = [
  { key: 'species', label: 'Species / type', placeholder: 'e.g. fox, robot, child' },
  { key: 'personality', label: 'Personality', placeholder: 'e.g. cheerful and brave' },
  { key: 'outfit', label: 'Outfit', placeholder: 'e.g. red hoodie and jeans' },
  { key: 'distinguishing_features', label: 'Distinguishing features', placeholder: 'e.g. big round glasses' },
]

export const STYLE_FIELDS: CharacterField[] = [
  { key: 'art_style', label: 'Art style', placeholder: 'e.g. 3D Pixar-like, flat 2D' },
  { key: 'palette', label: 'Colour palette', placeholder: 'e.g. warm pastels' },
]

/** Drops empty values so we never send blank attribute keys to the API. */
export function compact(record: Record<string, string>): Record<string, string> {
  return Object.fromEntries(
    Object.entries(record).filter(([, value]) => value.trim().length > 0),
  )
}
