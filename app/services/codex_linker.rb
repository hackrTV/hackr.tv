# Server-side port of app/javascript/utils/codexLinks.ts (Phase 1).
# Resolves [[Entry Name]] / [[Entry Name|custom text]] wiki syntax into
# markdown links to /codex/:slug, displaying canonical entry names from the
# published CodexEntry slug→name mapping (5-min cache, matches the SPA's
# useCodexMappings fetch of /api/codex/mappings).
#
# The slug algorithm must stay in lockstep with generateSlug in the TS
# module until Phase 7 deletes it.
class CodexLinker
  MAPPINGS_CACHE_KEY = "codex/linker/v1/mappings"
  MAPPINGS_TTL = 5.minutes
  WIKI_LINK = /\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/

  class << self
    def generate_slug(name)
      name.downcase
        .gsub(/[^a-z0-9\s-]/, "")
        .gsub(/\s+/, "-")
        .squeeze("-")
        .gsub(/\A-+|-+\z/, "")
    end

    def mappings
      Rails.cache.fetch(MAPPINGS_CACHE_KEY, expires_in: MAPPINGS_TTL, race_condition_ttl: 30.seconds) do
        CodexEntry.published.pluck(:slug, :name).to_h
      end
    end

    def transform_markdown(content)
      return content.to_s if content.blank?
      map = mappings
      content.gsub(WIKI_LINK) do
        entry_name = Regexp.last_match(1)
        custom_text = Regexp.last_match(2)
        slug = generate_slug(entry_name)
        display = custom_text.presence || map[slug] || entry_name
        "[#{display}](/codex/#{slug})"
      end
    end
  end
end
