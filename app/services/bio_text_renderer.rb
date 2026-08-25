# frozen_string_literal: true

# Server-side port of BioText.tsx: profile bios are plain text where ONLY
# word-boundary @mentions become links (to /wire/alias). Email local
# parts (me@gmail.com) never match — the mention must start the string or
# follow whitespace. External URLs stay inert plain text. Whitespace is
# preserved by CSS (pre-wrap), not markup.
class BioTextRenderer
  include ActionView::Helpers::TagHelper
  include ERB::Util

  MENTION = /(^|\s)(@[a-zA-Z0-9_]+)/

  def self.render(text)
    new.render(text)
  end

  def render(text)
    return "".html_safe if text.blank?

    out = +""
    pos = 0
    text.to_s.scan(MENTION) do
      match = Regexp.last_match
      out << h(text[pos...match.begin(0)]) if match.begin(0) > pos
      out << h(match[1]) # the leading whitespace (or "")
      alias_name = match[2].delete_prefix("@")
      out << tag.a(match[2], href: "/wire/#{alias_name}", class: "bio-mention").to_s
      pos = match.end(0)
    end
    out << h(text[pos..]) if pos < text.length

    out.html_safe
  end
end
