# Codex Entry Auto-Linking Helper
#
# Enables [[Entry Name]] wiki-style syntax to auto-link to Codex entries
# throughout the application (server-rendered views).
#
# Links always display the canonical entry name from the database, regardless
# of how the link is written (e.g., [[xeraen]], [[XERAEN]], [[the-pulse-grid]]
# will all display the official entry.name).
module CodexHelper
  # Generates a slug from an entry name using the same algorithm as CodexEntry model
  #
  # @param name [String] The entry name to convert to a slug
  # @return [String] URL-safe slug (lowercase, alphanumeric + hyphens only)
  #
  # @example
  #   generate_slug("The Fracture Network") #=> "the-fracture-network"
  #   generate_slug("XERAEN") #=> "xeraen"
  def generate_slug(name)
    name
      .downcase
      .gsub(/[^a-z0-9\s-]/, "") # Remove non-alphanumeric (except spaces/hyphens)
      .gsub(/\s+/, "-")          # Replace spaces with hyphens
      .squeeze("-")              # Squeeze multiple hyphens
      .gsub(/^-|-$/, "")         # Strip leading/trailing hyphens
  end

  # Looks up the canonical entry name from the database by slug
  # Caches results per-request to avoid N+1 queries
  #
  # @param slug [String] The entry slug to look up
  # @return [String, nil] The canonical entry name, or nil if not found
  def lookup_entry_name(slug)
    @codex_entry_cache ||= {}
    return @codex_entry_cache[slug] if @codex_entry_cache.key?(slug)

    entry = CodexEntry.published.find_by(slug: slug)
    @codex_entry_cache[slug] = entry&.name
  end

  # Transforms [[Entry Name]] syntax in text to HTML anchor tags
  #
  # Converts: [[Entry Name]] → <a href="/codex/entry-name">Canonical Name</a>
  # Converts: [[Entry Name|custom text]] → <a href="/codex/entry-name">custom text</a>
  # By default, displays the canonical entry name from the database.
  # Use pipe syntax to override display text while preserving the link target.
  # Automatically marks output as html_safe.
  #
  # @param content [String] Text content containing [[Entry Name]] syntax
  # @param css_class [String, nil] Optional CSS class to apply to generated links
  # @return [ActiveSupport::SafeBuffer] HTML string with wiki-style links converted to anchor tags
  #
  # @example
  #   codex_linkify("Connected to [[the-pulse-grid]]")
  #   #=> "Connected to <a href=\"/codex/the-pulse-grid\">The Pulse Grid</a>"
  #
  #   codex_linkify("See [[xeraen]]", css_class: "codex-link")
  #   #=> "See <a href=\"/codex/xeraen\" class=\"codex-link\">XERAEN</a>"
  #
  #   codex_linkify("Read about [[XERAEN|the legendary hackr]]")
  #   #=> "Read about <a href=\"/codex/xeraen\">the legendary hackr</a>"
  def codex_linkify(content, css_class: nil)
    return "" if content.blank?

    html_content = content.gsub(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/) do |_match|
      entry_name = ::Regexp.last_match(1)
      custom_text = ::Regexp.last_match(2)
      slug = generate_slug(entry_name)

      # Use custom text if provided, otherwise look up canonical name from database
      display_name = if custom_text.present?
        custom_text
      else
        lookup_entry_name(slug) || entry_name
      end

      class_attr = css_class.present? ? %( class="#{ERB::Util.html_escape(css_class)}") : ""
      %(<a href="/codex/#{ERB::Util.html_escape(slug)}"#{class_attr}>#{ERB::Util.html_escape(display_name)}</a>)
    end

    html_content.html_safe
  end

  # Transforms [[Entry Name]] syntax in markdown to standard markdown links
  #
  # Converts: [[Entry Name]] → [Canonical Name](/codex/entry-name)
  # Converts: [[Entry Name|custom text]] → [custom text](/codex/entry-name)
  # By default, displays the canonical entry name from the database.
  # Use pipe syntax to override display text while preserving the link target.
  # Use this for content that will be processed by a markdown parser.
  #
  # @param content [String] Markdown content containing [[Entry Name]] syntax
  # @return [String] Markdown with wiki-style links converted to standard link syntax
  #
  # @example
  #   markdown_codex_links("Read about [[xeraen]] and [[the-fracture-network]]")
  #   #=> "Read about [XERAEN](/codex/xeraen) and [The Fracture Network](/codex/the-fracture-network)"
  #
  #   markdown_codex_links("Learn from [[XERAEN|the best hackr in the grid]]")
  #   #=> "Learn from [the best hackr in the grid](/codex/xeraen)"
  def markdown_codex_links(content)
    return "" if content.blank?

    content.gsub(/\[\[([^\]|]+)(?:\|([^\]]+))?\]\]/) do |_match|
      entry_name = ::Regexp.last_match(1)
      custom_text = ::Regexp.last_match(2)
      slug = generate_slug(entry_name)

      # Use custom text if provided, otherwise look up canonical name from database
      display_name = if custom_text.present?
        custom_text
      else
        lookup_entry_name(slug) || entry_name
      end

      "[#{display_name}](/codex/#{slug})"
    end
  end

  # Extracts all [[Entry Name]] references from content
  #
  # Useful for:
  # - Building "Referenced in" sections on Codex entries
  # - Validating that all referenced entries exist
  # - Generating dependency graphs
  #
  # @param content [String] Content containing [[Entry Name]] syntax
  # @return [Array<String>] Array of entry names (deduplicated)
  #
  # @example
  #   extract_codex_references("[[XERAEN]] works with [[The Fracture Network]] and [[XERAEN]]")
  #   #=> ["XERAEN", "The Fracture Network"]
  def extract_codex_references(content)
    return [] if content.blank?

    content.scan(/\[\[([^\]]+)\]\]/).flatten.uniq
  end

  # Checks if content contains any [[Entry Name]] syntax
  #
  # @param content [String] Content to check
  # @return [Boolean] true if content contains at least one [[Entry Name]] reference
  #
  # @example
  #   has_codex_links?("See [[XERAEN]]") #=> true
  #   has_codex_links?("No links here") #=> false
  def has_codex_links?(content)
    return false if content.blank?

    content.match?(/\[\[([^\]]+)\]\]/)
  end
end
