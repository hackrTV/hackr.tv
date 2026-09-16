# Chrome helpers for the TUI design system (Phase 2 CS1, plan in SMR
# plans/tui_components/plan.md). Server-logic buttons (link/submit/button_to)
# go through these. Sanctioned raw "tui-button" survivors: Stimulus-wired
# <button> markup (data-action/aria-heavy — attribute hashes would obscure
# the wiring, and the data-turbo-permanent player bar must not drift),
# <span>/<label> styled as buttons, and client-side JS string builders.
module TuiHelper
  TUI_BUTTON_COLORS = %w[green purple red cyan yellow grey orange].freeze

  # Class-string builder and escape hatch for sites that need a raw string
  # (conditional color logic, JS-built markup parity).
  def tui_button_classes(color = nil, extra = nil)
    classes = ["tui-button"]
    if color
      color = color.to_s
      unless TUI_BUTTON_COLORS.include?(color)
        raise ArgumentError, "unknown tui-button color #{color.inspect} (valid: #{TUI_BUTTON_COLORS.join(", ")})"
      end
      classes << "#{color}-168"
    end
    classes << extra if extra.present?
    classes.join(" ")
  end

  # Anchor when url is given, <button> otherwise. Block form for rich content:
  #   <%= tui_button "/vault", color: :cyan do %>...<% end %>
  def tui_button(label = nil, url = nil, color: nil, **options, &block)
    options[:class] = tui_button_classes(color, options[:class])
    if block
      url, label = label, nil if url.nil?
      return link_to(url, options, &block) if url
    elsif url
      return link_to(label, url, options)
    end
    # button_tag defaults name="button" (adds a phantom form param raw
    # <button> markup never had); suppress unless the caller asks for one.
    options[:name] = nil unless options.key?(:name)
    block ? button_tag(options, &block) : button_tag(label, options)
  end

  def tui_button_to(label, url, color: nil, **options)
    options[:class] = tui_button_classes(color, options[:class])
    button_to(label, url, options)
  end

  def tui_submit(label, form: nil, color: nil, **options)
    options[:class] = tui_button_classes(color, options[:class])
    form ? form.submit(label, options) : submit_tag(label, options)
  end
end
