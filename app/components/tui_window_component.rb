# frozen_string_literal: true

# Unified TUI panel chrome (Phase 2 CS4, plan in SMR plans/tui_components/
# plan.md) — replaces the hand-rolled div.tui-window > fieldset > legend
# idiom. Branded windows (artist/band/catalog themes) keep raw markup by
# design, same carve-out as CS1's client-wired buttons.
#
#   <%= render TuiWindowComponent.new(title: "/root/zones :: MANAGE") do %>
#     ...body...
#   <% end %>
#
# Variants: :admin (centered page wrapper, admin night-blue chrome, width
# defaults 1400), :page (centered page wrapper, DOS black), :panel (inner
# block panel, bg #0a0a0a), :plain (no layout class — tuicss base rendering
# only). Layout/spacing beyond the shared chrome passes through via
# style:/class:.
class TuiWindowComponent < ViewComponent::Base
  COLORS = %w[green purple red cyan yellow orange].freeze

  def initialize(title: nil, variant: :panel, width: nil, color: nil,
    fieldset: true, legend_class: "center", fieldset_class: nil, **html_options)
    unless %i[admin page panel plain].include?(variant)
      raise ArgumentError, "unknown TuiWindow variant #{variant.inspect}"
    end
    if color && !COLORS.include?(color.to_s)
      raise ArgumentError, "unknown TuiWindow color #{color.inspect} (valid: #{COLORS.join(", ")})"
    end
    raise ArgumentError, "title requires a fieldset (legend)" if title && !fieldset

    @title = title
    @fieldset = fieldset
    @variant = variant
    @width = width || ((variant == :admin) ? 1400 : nil)
    @color = color
    @legend_class = legend_class
    @fieldset_class = fieldset_class
    @html_options = html_options
  end

  private

  attr_reader :title, :variant, :width, :color, :legend_class

  def fieldset?
    @fieldset
  end

  def root_options
    classes = ["tui-window"]
    classes << "#{color}-168" if color
    classes << "white-text"
    classes << "admin-panel" if variant == :admin
    case variant
    when :panel then classes << "tui-window--panel"
    when :admin, :page then classes << "tui-window--page"
    end
    classes << @html_options[:class] if @html_options[:class]

    style = [width && "max-width: #{width}px", @html_options[:style]].compact.join("; ")
    @html_options.merge(class: classes.join(" "), style: style.presence)
  end

  def fieldset_classes
    return @fieldset_class if @fieldset_class
    return "admin-panel-border" if variant == :admin
    "#{color}-168-border" if color
  end
end
