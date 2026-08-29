# frozen_string_literal: true

# Chat packet text (Packet.tsx renderContent port): WireTextRenderer's
# codex/link/censor rules, plus @mention links on the plain-text
# segments between tokens — mirroring the SPA's URL-pass-then-mentions
# order (mentions never render inside link labels). Mention links are
# viewer-neutral; the packet Stimulus controller highlights the viewer's
# own alias from the layout's current-hackr-alias meta.
class UplinkTextRenderer < WireTextRenderer
  # The SPA matched @alias anywhere in the string; this adds the bio
  # renderer's guard so email local parts (me@gmail.com) don't mislink —
  # the character before "@" must not read as part of an address.
  MENTION = /(^|[^A-Za-z0-9_.])@([A-Za-z0-9_]+)/

  protected

  def plain(text)
    out = +""
    pos = 0
    text.scan(MENTION) do
      match = Regexp.last_match
      out << h(text[pos...match.begin(0)]) if match.begin(0) > pos
      out << h(match[1]) # the boundary character (or "")
      out << tag.a("@#{match[2]}", href: "/wire/#{match[2]}",
        class: "uplink-mention", data: {alias: match[2]}).to_s
      pos = match.end(0)
    end
    out << h(text[pos..]) if pos < text.length
    out
  end
end
