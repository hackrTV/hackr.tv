# View helpers for server-rendered content pages (Hotwire migration Phase 1).
module ContentHelper
  # Port of dateUtils.formatFutureDate: +100 years for the 2120s setting.
  # "January 5, 2126" / "January 5, 2126 at 3:07 PM".
  def future_datetime(datetime, include_time: false)
    return "" if datetime.blank?
    shifted = datetime + 100.years
    formatted = shifted.strftime("%B %-d, %Y")
    formatted += shifted.strftime(" at %-I:%M %p") if include_time
    formatted
  end

  # Markdown for content pages: [[codex links]] resolved, rendered +
  # sanitized, then internal anchors to not-yet-migrated paths marked
  # data-turbo=false (a Turbo visit into the React SPA shell would blank —
  # the SPA mounts on DOMContentLoaded, which never fires on Turbo visits).
  def markdown_content(text)
    html = MarkdownRenderer.render_user(CodexLinker.transform_markdown(text))
    hotwireize_links(html)
  end

  # Port of LogsIndexPage truncateMarkdown: strip md symbols, links → text,
  # truncate. ([[wiki]] refs pass through untouched — matches the SPA.)
  def markdown_plain_excerpt(markdown, max_length: 300)
    plain = markdown.to_s
      .gsub(/[#*_`]/, "")
      .gsub(/\[([^\]]+)\]\([^)]+\)/, '\1')
      .strip
    return plain if plain.length <= max_length
    plain[0, max_length].strip + "..."
  end

  def hotwireize_links(html)
    fragment = Nokogiri::HTML5.fragment(html)
    fragment.css("a[href]").each do |a|
      href = a["href"].to_s
      next unless href.start_with?("/")
      # Internal links: same-tab navigation (Redcarpet's link_attributes adds
      # target=_blank + nofollow to every link — correct for external only;
      # the SPA rendered internal links as Router links without either).
      a.remove_attribute("target")
      a.remove_attribute("rel")
      a["data-turbo"] = "false" unless hotwire_path?(href)
    end
    fragment.to_html.html_safe
  end

  # Port of CodexText.tsx for plain lore copy (station descriptions,
  # artist blurbs): [[Entry]] / [[Entry|display]] become codex links,
  # everything else is escaped. Not WireTextRenderer — that also censors
  # external links, which is wrong for editorial text.
  def codex_text(text)
    mappings = CodexLinker.mappings
    parts = text.to_s.split(/(\[\[[^\]]+\]\])/)
    safe_join(parts.map { |part|
      if part =~ /\A\[\[([^\]|]+)(?:\|([^\]]+))?\]\]\z/
        slug = CodexLinker.generate_slug($1)
        link_to($2.presence || mappings[slug] || $1, "/codex/#{slug}", class: "codex-link")
      else
        part
      end
    })
  end

  # Port of CodeIndexPage formatDate: relative "3d ago" style.
  def code_relative_date(datetime)
    return "N/A" if datetime.blank?
    days = ((Time.current - datetime) / 1.day).floor
    return "today" if days.zero?
    return "yesterday" if days == 1
    return "#{days}d ago" if days < 30
    return "#{days / 30}mo ago" if days < 365
    "#{days / 365}y ago"
  end

  # Port of CodeBlobView formatSize.
  def code_format_size(bytes)
    return "#{bytes} B" if bytes < 1024
    return "#{(bytes / 1024.0).round(1)} KB" if bytes < 1024 * 1024
    "#{(bytes / (1024.0 * 1024)).round(1)} MB"
  end

  # Rouge replaces highlight.js: lexer by service-detected language, then
  # filename guess, then plaintext.
  def rouge_highlight(content, language, filename)
    lexer = Rouge::Lexer.find(language.to_s.downcase) ||
      Rouge::Lexer.guess(filename: filename.to_s, source: content) { Rouge::Lexers::PlainText.new }
    formatter = Rouge::Formatters::HTML.new
    content_tag(:div, formatter.format(lexer.lex(content)).html_safe, class: "highlight")
  end

  # Port of StreamSchedulePage formatDuration: "45m" / "2h 05m"-style.
  def stream_duration(start_time, end_time)
    return "—" if start_time.blank? || end_time.blank?
    minutes = ((end_time - start_time) / 60).floor
    return "#{minutes}m" if minutes < 60
    "#{minutes / 60}h #{minutes % 60}m"
  end

  # Port of timelineConfig formatEra.
  def timeline_era(info)
    return "" if info[:min_year].nil? || info[:max_year].nil?
    return info[:min_year].to_s if info[:min_year] == info[:max_year]
    "#{info[:min_year]}–#{info[:max_year]}"
  end
end
