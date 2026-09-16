# Admin form-field chrome (Phase 2 CS2, plan in SMR plans/tui_components/
# plan.md). Default builder for Admin::ApplicationController forms; renders
# the label + tui-input + hint + inline-errors idiom the admin forms
# previously hand-rolled per field. Styling: tuicss.css .tui-field* rules.
#
#   <%= f.tui_text_field :name %>                        label defaults to NAME
#   <%= f.tui_select :rarity, CHOICES, {include_blank: "Select..."} %>
#   <%= f.tui_text_area :description, hint: "shown to players", rows: 4 %>
#   <%= f.tui_check_box :active, label: "ACTIVE" %>      label wraps the box
class TuiFormBuilder < ActionView::Helpers::FormBuilder
  FIELD_HELPERS = %i[
    text_field text_area number_field password_field email_field url_field
    date_field datetime_field datetime_local_field color_field file_field
  ].freeze

  FIELD_HELPERS.each do |field_helper|
    define_method(:"tui_#{field_helper}") do |method, label: nil, hint: nil, **options|
      tui_field(method, label:, hint:) do
        public_send(field_helper, method, {class: "tui-input"}.merge(options))
      end
    end
  end

  def tui_select(method, choices = nil, options = {}, label: nil, hint: nil, **html_options)
    tui_field(method, label:, hint:) do
      select(method, choices, options, {class: "tui-input"}.merge(html_options))
    end
  end

  def tui_collection_select(method, collection, value_method, text_method, options = {}, label: nil, hint: nil, **html_options)
    tui_field(method, label:, hint:) do
      collection_select(method, collection, value_method, text_method, options, {class: "tui-input"}.merge(html_options))
    end
  end

  def tui_check_box(method, label: nil, hint: nil, **options)
    @template.tag.div(class: "tui-field tui-field--check") do
      box = label(method, class: "tui-field-label") do
        @template.safe_join([check_box(method, options), label || default_label(method)], " ")
      end
      @template.safe_join([box, hint_tag(hint), error_tag(method)].compact)
    end
  end

  private

  def tui_field(method, label:, hint:)
    @template.tag.div(class: "tui-field") do
      parts = [label(method, label || default_label(method), class: "tui-field-label")]
      parts << yield
      parts << hint_tag(hint)
      parts << error_tag(method)
      @template.safe_join(parts.compact)
    end
  end

  def default_label(method)
    method.to_s.humanize.upcase
  end

  def hint_tag(hint)
    return if hint.blank?
    @template.tag.small(hint, class: "tui-field-hint")
  end

  def error_tag(method)
    messages = object.respond_to?(:errors) ? object.errors[method] : []
    return if messages.blank?
    @template.tag.small(messages.join(", "), class: "tui-field-error")
  end
end
