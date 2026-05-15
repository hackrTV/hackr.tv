import DOMPurify from 'dompurify'

// Shared HTML sanitizer for all dangerouslySetInnerHTML usage.
// Allows inline styles (used extensively by command output) and
// standard formatting tags. Strips scripts, event handlers, etc.
export function sanitizeHtml (html: string): string {
  return DOMPurify.sanitize(html, {
    ALLOWED_TAGS: ['span', 'div', 'br', 'b', 'i', 'em', 'strong', 'a', 'p', 'svg', 'path', 'rect', 'circle', 'g'],
    ALLOWED_ATTR: ['style', 'class', 'href', 'target', 'rel', 'viewBox', 'xmlns', 'd', 'fill', 'width', 'height', 'x', 'y', 'rx', 'ry', 'transform']
  })
}
