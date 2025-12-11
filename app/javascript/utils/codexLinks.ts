/**
 * Codex Entry Auto-Linking Utilities
 *
 * Enables [[Entry Name]] wiki-style syntax to auto-link to Codex entries
 * throughout the application. Works in markdown content, plain text, and HTML.
 *
 * When mappings are provided, links always display the canonical entry name
 * from the database (e.g., [[xeraen]], [[the-pulse-grid]], [[XERAEN]] will all
 * display as "XERAEN" and "The Pulse Grid" respectively).
 *
 * For entries without Codex pages (e.g., bands), fallback routes can be
 * configured to link to band profile pages instead.
 */

/**
 * Codex slug->name mapping type
 * e.g., { "xeraen": "XERAEN", "the-pulse-grid": "The Pulse Grid" }
 */
export type CodexMappings = Record<string, string>

/**
 * Fallback routes for entries without Codex pages
 * Maps slug -> { route: string, displayName: string }
 *
 * When a [[Entry Name]] reference doesn't have a Codex entry,
 * check this mapping to link to an alternative page (e.g., band profiles)
 */
export const CODEX_FALLBACK_ROUTES: Record<string, { route: string; displayName: string }> = {
  'voiceprint': { route: '/voiceprint', displayName: 'Voiceprint' },
  'cipher-protocol': { route: '/cipher_protocol', displayName: 'Cipher Protocol' },
  'injection-vector': { route: '/injection_vector', displayName: 'Injection Vector' },
  'wavelength-zero': { route: '/wavelength_zero', displayName: 'Wavelength Zero' },
  'system-rot': { route: '/system_rot', displayName: 'System Rot' },
  'temporal-blue-drift': { route: '/temporal_blue_drift', displayName: 'Temporal Blue Drift' },
  'offline': { route: '/offline', displayName: 'Offline' },
  'apex-overdrive': { route: '/apex_overdrive', displayName: 'Apex Overdrive' },
  'neon-hearts': { route: '/neon_hearts', displayName: 'Neon Hearts (ネオンハーツ)' },
  'ethereality': { route: '/ethereality', displayName: 'Ethereality' },
  'blitzbeam': { route: '/blitzbeam', displayName: 'BlitzBeam+' }
}

/**
 * Gets the route for a given slug, checking fallbacks if no Codex entry exists
 *
 * @param slug - The entry slug
 * @returns The route path (either /codex/{slug} or a fallback route)
 */
export const getRouteForSlug = (slug: string): string => {
  const fallback = CODEX_FALLBACK_ROUTES[slug]
  if (fallback) {
    return fallback.route
  }
  return `/codex/${slug}`
}

/**
 * Gets the display name for a slug from fallback routes
 *
 * @param slug - The entry slug
 * @returns The display name if found in fallbacks, undefined otherwise
 */
export const getFallbackDisplayName = (slug: string): string | undefined => {
  return CODEX_FALLBACK_ROUTES[slug]?.displayName
}

/**
 * Generates a slug from an entry name using the same algorithm as CodexEntry model
 *
 * @param name - The entry name to convert to a slug
 * @returns URL-safe slug (lowercase, alphanumeric + hyphens only)
 *
 * @example
 * generateSlug("The Fracture Network") // => "the-fracture-network"
 * generateSlug("XERAEN") // => "xeraen"
 * generateSlug("[[Entry Name]]") // => "entry-name"
 */
export const generateSlug = (name: string): string => {
  return name
    .toLowerCase()
    .replace(/[^a-z0-9\s-]/g, '') // Remove non-alphanumeric (except spaces/hyphens)
    .replace(/\s+/g, '-')          // Replace spaces with hyphens
    .replace(/-+/g, '-')           // Squeeze multiple hyphens
    .replace(/^-|-$/g, '')        // Strip leading/trailing hyphens
}

/**
 * Transforms [[Entry Name]] syntax in markdown to standard markdown links
 *
 * Converts: [[Entry Name]] → [Canonical Name](/codex/entry-name)
 * Converts: [[Entry Name|custom text]] → [custom text](/codex/entry-name)
 * When mappings are provided, displays the canonical entry name from the database.
 * Use pipe syntax to override display text while preserving the link target.
 * Use this for content that will be processed by ReactMarkdown or other markdown parsers.
 *
 * @param content - Markdown content containing [[Entry Name]] syntax
 * @param mappings - Optional slug->name mapping for canonical names
 * @returns Markdown with wiki-style links converted to standard link syntax
 *
 * @example
 * // Without mappings (displays typed text)
 * transformMarkdownLinks("Read about [[xeraen]]")
 * // => "Read about [xeraen](/codex/xeraen)"
 *
 * // With mappings (displays canonical name)
 * const mappings = { "xeraen": "XERAEN", "the-pulse-grid": "The Pulse Grid" }
 * transformMarkdownLinks("Read about [[xeraen]] and [[the-pulse-grid]]", mappings)
 * // => "Read about [XERAEN](/codex/xeraen) and [The Pulse Grid](/codex/the-pulse-grid)"
 *
 * // With custom text (overrides mappings)
 * transformMarkdownLinks("Learn from [[XERAEN|the legendary hackr]]", mappings)
 * // => "Learn from [the legendary hackr](/codex/xeraen)"
 */
export const transformMarkdownLinks = (content: string, mappings?: CodexMappings): string => {
  return content.replace(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/g, (_match, entryName, customText) => {
    const slug = generateSlug(entryName)
    // Use custom text if provided, otherwise use canonical name from mappings, then fallbacks, then entry name
    const displayName = customText || (mappings && mappings[slug]) || getFallbackDisplayName(slug) || entryName
    // Get route (checks fallbacks for entries without Codex pages)
    const route = getRouteForSlug(slug)
    return `[${displayName}](${route})`
  })
}

/**
 * Transforms [[Entry Name]] syntax in plain text to HTML anchor tags
 *
 * Converts: [[Entry Name]] → <a href="/codex/entry-name">Canonical Name</a>
 * Converts: [[Entry Name|custom text]] → <a href="/codex/entry-name">custom text</a>
 * When mappings are provided, displays the canonical entry name from the database.
 * Use pipe syntax to override display text while preserving the link target.
 * Use this for plain text content that will be rendered as HTML (not markdown).
 *
 * @param content - Plain text content containing [[Entry Name]] syntax
 * @param mappings - Optional slug->name mapping for canonical names
 * @param className - Optional CSS class to apply to generated links
 * @returns HTML string with wiki-style links converted to anchor tags
 *
 * @example
 * // Without mappings (displays typed text)
 * transformHtmlLinks("Connected to [[the-pulse-grid]]")
 * // => "Connected to <a href=\"/codex/the-pulse-grid\">the-pulse-grid</a>"
 *
 * // With mappings (displays canonical name)
 * const mappings = { "xeraen": "XERAEN" }
 * transformHtmlLinks("See [[xeraen]]", mappings, "codex-link")
 * // => "See <a href=\"/codex/xeraen\" class=\"codex-link\">XERAEN</a>"
 *
 * // With custom text (overrides mappings)
 * transformHtmlLinks("Learn from [[XERAEN|the best]]", mappings, "codex-link")
 * // => "Learn from <a href=\"/codex/xeraen\" class=\"codex-link\">the best</a>"
 */
export const transformHtmlLinks = (
  content: string,
  mappings?: CodexMappings,
  className?: string
): string => {
  return content.replace(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/g, (_match, entryName, customText) => {
    const slug = generateSlug(entryName)
    // Use custom text if provided, otherwise use canonical name from mappings, then fallbacks, then entry name
    const displayName = customText || (mappings && mappings[slug]) || getFallbackDisplayName(slug) || entryName
    // Get route (checks fallbacks for entries without Codex pages)
    const route = getRouteForSlug(slug)
    const classAttr = className ? ` class="${className}"` : ''
    return `<a href="${route}"${classAttr}>${displayName}</a>`
  })
}

/**
 * Extracts all [[Entry Name]] references from content
 *
 * Useful for:
 * - Building "Referenced in" sections on Codex entries
 * - Validating that all referenced entries exist
 * - Generating dependency graphs
 *
 * @param content - Content containing [[Entry Name]] syntax
 * @returns Array of entry names (deduplicated)
 *
 * @example
 * extractCodexReferences("[[XERAEN]] works with [[The Fracture Network]] and [[XERAEN]]")
 * // => ["XERAEN", "The Fracture Network"]
 */
export const extractCodexReferences = (content: string): string[] => {
  const matches = content.matchAll(/\[\[([^\]]+)\]\]/g)
  const names = Array.from(matches, match => match[1])
  return [...new Set(names)] // Deduplicate
}

/**
 * Checks if content contains any [[Entry Name]] syntax
 *
 * @param content - Content to check
 * @returns true if content contains at least one [[Entry Name]] reference
 *
 * @example
 * hasCodexLinks("See [[XERAEN]]") // => true
 * hasCodexLinks("No links here") // => false
 */
export const hasCodexLinks = (content: string): boolean => {
  return /\[\[([^\]]+)\]\]/.test(content)
}
