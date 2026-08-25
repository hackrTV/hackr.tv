# frozen_string_literal: true

# Server-side port of the SPA's WireText pipeline (WireText.tsx +
# utils/urlContent.tsx + CodexText): pulse content is plain text — never
# markdown-rendered — with exactly three token transformations:
#
#   [[Codex Ref]] / [[Codex Ref|display]]  → <a href="/codex/slug">
#   [label](https://…)  → admin: <a target=_blank>label</a>
#                         non-admin: censor span (label dropped — SPA parity)
#   https://…           → admin: link; non-admin: censor span
#                         (trailing sentence punctuation stays plain text)
#
# One alternation scan; everything between tokens is HTML-escaped, so the
# html_safe output is built exclusively from escaped fragments.
class WireTextRenderer
  include ActionView::Helpers::TagHelper
  include ERB::Util

  TOKEN = %r{
    \[\[([^\]|]+)(?:\|([^\]]+))?\]\]              # 1,2: [[wiki ref|display]]
    | \[([^\]]+)\]\((https?://[^\s)]+)\)          # 3,4: [label](url)
    | \b(https?://[^\s<]+)                        # 5: bare url
  }xi
  TRAILING_PUNCTUATION = /[.,;:!?\])’']+\z/
  CENSOR_TEXT = "[LINK CENSORED BY GOVCORP]"

  def self.render(content, poster_is_admin: false)
    new(poster_is_admin: poster_is_admin).render(content)
  end

  def initialize(poster_is_admin: false)
    @poster_is_admin = poster_is_admin
  end

  def render(content)
    return "".html_safe if content.blank?

    mappings = CodexLinker.mappings
    out = +""
    pos = 0

    content.to_s.scan(TOKEN) do
      match = Regexp.last_match
      out << h(content[pos...match.begin(0)]) if match.begin(0) > pos
      out << render_token(match, mappings)
      pos = match.end(0)
    end
    out << h(content[pos..]) if pos < content.length

    out.html_safe
  end

  private

  def render_token(match, mappings)
    if match[1] # [[wiki ref]]
      codex_link(match[1], match[2], mappings)
    elsif match[3] # [label](url)
      @poster_is_admin ? external_link(match[4], label: match[3]) : censor_span
    else # bare url
      bare_url(match[5])
    end
  end

  def codex_link(name, display_override, mappings)
    slug = CodexLinker.generate_slug(name)
    display = display_override.presence || mappings[slug] || name
    tag.a(display, href: "/codex/#{slug}", class: "codex-link").to_s
  end

  def bare_url(url)
    trailer = url[TRAILING_PUNCTUATION] || ""
    url = url.delete_suffix(trailer)
    rendered = @poster_is_admin ? external_link(url, label: url) : censor_span
    rendered + h(trailer)
  end

  def external_link(url, label:)
    tag.a(label, href: url, target: "_blank", rel: "noopener noreferrer", class: "wire-external-link").to_s
  end

  def censor_span
    tag.span(CENSOR_TEXT, class: "wire-censored").to_s
  end
end
