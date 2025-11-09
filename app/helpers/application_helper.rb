module ApplicationHelper
  def markdown(text)
    return "" if text.blank?

    options = {
      filter_html: false,
      hard_wrap: true,
      link_attributes: {rel: "nofollow", target: "_blank"},
      space_after_headers: true,
      fenced_code_blocks: true
    }

    extensions = {
      autolink: true,
      superscript: true,
      disable_indented_code_blocks: false,
      fenced_code_blocks: true,
      strikethrough: true,
      tables: true
    }

    renderer = Redcarpet::Render::HTML.new(options)
    markdown = Redcarpet::Markdown.new(renderer, extensions)

    markdown.render(text).html_safe
  end

  def markdown_excerpt(text, length: 300)
    return "" if text.blank?

    # Render markdown first
    rendered = markdown(text)
    # Strip HTML tags
    plain_text = strip_tags(rendered)
    # Truncate
    truncate(plain_text, length: length, separator: " ", omission: "...")
  end

  # Add 100 years to dates for lore-appropriate display (2125 setting)
  def future_date(date)
    return nil if date.blank?
    date + 100.years
  end
end
