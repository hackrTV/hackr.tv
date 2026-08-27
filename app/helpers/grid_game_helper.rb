module GridGameHelper
  # DOMPurify-config parity from the SPA's sanitizeHtml.ts.
  ALLOWED_TAGS = %w[span div br b i em strong a p table tr td th].freeze
  ALLOWED_ATTRIBUTES = %w[style class href].freeze

  # Parser output is server-authored HTML (colored spans), but it can
  # embed player-influenced strings — sanitize mirrors the SPA's
  # DOMPurify pass (defense in depth).
  def grid_output(html)
    sanitize(html, tags: ALLOWED_TAGS, attributes: ALLOWED_ATTRIBUTES)
  end
end
