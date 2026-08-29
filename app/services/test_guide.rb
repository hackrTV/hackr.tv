# Reads the manual testing guide from docs/testing/*.md (single source of
# truth for the /root/test_guide UI and the offline docs). Filenames are
# ordered (NN_slug.md); YAML frontmatter carries title/area/minutes.
#
# Slug lookups only ever resolve against the scanned file list — params
# never touch the filesystem directly.
class TestGuide
  DOCS_DIR = Rails.root.join("docs/testing")
  FRONTMATTER = /\A---\s*\n(.*?)\n---\s*\n/m

  Article = Struct.new(:slug, :title, :area, :minutes, :position, :body_markdown) do
    def body_html
      html = MarkdownRenderer.render_trusted(body_markdown)
      TestGuide.checkboxify(html, slug)
    end
  end

  class << self
    def articles
      DOCS_DIR.glob("[0-9][0-9]_*.md").sort.map.with_index do |path, index|
        parse(path, index)
      end
    end

    def find(slug)
      articles.find { |a| a.slug == slug }
    end

    def areas
      articles.group_by(&:area)
    end

    def neighbors(slug)
      all = articles
      index = all.index { |a| a.slug == slug }
      return [nil, nil] unless index
      [index.positive? ? all[index - 1] : nil, all[index + 1]]
    end

    def total_minutes
      articles.sum { |a| a.minutes.to_i }
    end

    # Render markdown task-ish steps as interactive checkboxes: every
    # <li> in an ordered list under "## Steps" stays plain HTML, but we
    # tag list items with data attributes so the admin view's inline JS
    # can attach persistent (localStorage) checkboxes per run + article.
    def checkboxify(html, slug)
      fragment = Nokogiri::HTML5.fragment(html)
      fragment.css("ol > li").each_with_index do |li, index|
        li["data-step"] = "#{slug}:#{index}"
        li["class"] = [li["class"], "tg-step"].compact.join(" ")
      end
      fragment.to_html.html_safe
    end

    private

    def parse(path, index)
      raw = path.read
      meta = {}
      if (match = raw.match(FRONTMATTER))
        meta = YAML.safe_load(match[1]) || {}
        raw = match.post_match
      end
      Article.new(
        slug: path.basename(".md").to_s,
        title: meta["title"] || path.basename(".md").to_s.tr("_", " "),
        area: meta["area"] || "General",
        minutes: meta["minutes"].to_i,
        position: index,
        body_markdown: raw
      )
    end
  end
end
