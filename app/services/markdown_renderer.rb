# Server-side markdown pipeline for the Hotwire migration (Phase 0).
#
# Profiles:
#   render_trusted — admin/system-authored content (codex, handbook, hackr
#     logs). Same Redcarpet options as ApplicationHelper#markdown; raw HTML
#     passes through.
#   render_user — user-generated content (bio, wire posts). Rendered, then
#     sanitized with an allowlist mirroring the SPA's rehype-sanitize
#     defaults. Page-specific rules (@mention linking, codex links, email
#     exclusion) layer on top in Phases 1/3.
#
# Redcarpet::Markdown instances are not thread-safe, so one is built per
# call (matches the existing helper).
class MarkdownRenderer
  OPTIONS = {
    filter_html: false,
    hard_wrap: true,
    link_attributes: {rel: "nofollow", target: "_blank"},
    space_after_headers: true,
    fenced_code_blocks: true
  }.freeze

  EXTENSIONS = {
    autolink: true,
    superscript: true,
    disable_indented_code_blocks: false,
    fenced_code_blocks: true,
    strikethrough: true,
    tables: true
  }.freeze

  USER_ALLOWED_TAGS = %w[
    p br strong b em i del code pre blockquote ul ol li a
    h1 h2 h3 h4 h5 h6 table thead tbody tr th td hr sup span
  ].freeze
  USER_ALLOWED_ATTRIBUTES = %w[href rel target class].freeze

  class << self
    def render_trusted(text)
      return "" if text.blank?
      markdown.render(text).html_safe
    end

    def render_user(text)
      return "" if text.blank?
      html = markdown.render(text)
      sanitizer.sanitize(html, tags: USER_ALLOWED_TAGS, attributes: USER_ALLOWED_ATTRIBUTES).html_safe
    end

    private

    def markdown
      Redcarpet::Markdown.new(Redcarpet::Render::HTML.new(OPTIONS), EXTENSIONS)
    end

    def sanitizer
      Rails::HTML5::SafeListSanitizer.new
    end
  end
end
