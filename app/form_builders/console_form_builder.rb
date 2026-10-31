# The /root console's form fields (2026-10-30) — the admin's default
# builder (Admin::ApplicationController). Each rc_* helper renders the
# .console-status-row.rc-field row the music _forms set the idiom with:
#
#   <div class="console-status-row rc-field">
#     <label class="console-key" for="artist_name">NAME</label>
#     <span class="console-val"><input class="rc-input" …><span class="rc-hint">…</span><span class="rc-err">…</span></span>
#   </div>
#
#   <%= f.rc_text_field :name, required: true %>                      label defaults to NAME
#   <%= f.rc_text_field :catalog_number, label: "CATALOG #", width: :short %>
#   <%= f.rc_select :artist_id, choices, {include_blank: "—"}, hint: "…" %>
#   <%= f.rc_text_area :description, rows: 4 %>                       // DESCRIPTION // + growing textarea
#   <%= f.rc_flags("FLAGS", hint: "…") { f.rc_check_box(:featured, label: "★ FEATURED") } %>
#
# Styling: root_console.css .rc-*. Inherits TuiFormBuilder's tui_*
# family while the legacy admin forms still call it (gone with Phase 6
# of console-ui-for-all-admin — then the superclass is
# ActionView::Helpers::FormBuilder).
class ConsoleFormBuilder < TuiFormBuilder
  FIELD_HELPERS = %i[
    text_field number_field password_field email_field url_field
    date_field datetime_local_field time_field color_field file_field
  ].freeze

  WIDTHS = {short: "rc-input--short", date: "rc-input--date", wide: "rc-input--wide"}.freeze

  FIELD_HELPERS.each do |field_helper|
    define_method(:"rc_#{field_helper}") do |method, label: nil, hint: nil, width: nil, **options|
      width ||= :date if field_helper.start_with?("date")
      rc_field(method, label:, hint:) do
        public_send(field_helper, method, options.merge(class: rc_class("rc-input", WIDTHS[width], options[:class])))
      end
    end
  end

  def rc_select(method, choices = nil, options = {}, label: nil, hint: nil, **html_options)
    rc_field(method, label:, hint:) do
      select(method, choices, options, html_options.merge(class: rc_class("rc-select", html_options[:class])))
    end
  end

  def rc_collection_select(method, collection, value_method, text_method, options = {}, label: nil, hint: nil, **html_options)
    rc_field(method, label:, hint:) do
      collection_select(method, collection, value_method, text_method, options, html_options.merge(class: rc_class("rc-select", html_options[:class])))
    end
  end

  # <label class="rc-check"><input type="checkbox"> LABEL</label> — inline,
  # no row of its own: a row of them is rc_flags.
  def rc_check_box(method, label: nil, **options)
    @template.tag.label(class: "rc-check") do
      @template.safe_join([check_box(method, options), label || rc_label(method)], " ")
    end
  end

  # One status row holding the block's rc_check_boxes (the tracks FLAGS
  # row), the hint after them.
  def rc_flags(label, hint: nil, &block)
    @template.tag.div(class: "console-status-row rc-field") do
      @template.tag.span(label, class: "console-key") +
        @template.tag.span(class: "console-val") { @template.safe_join([@template.capture(&block), rc_hint(hint)].compact) }
    end
  end

  # // LABEL // + a growing textarea, then the hint / error as a dim
  # note under it.
  def rc_text_area(method, label: nil, hint: nil, rows: 4, autogrow: true, **options)
    data = options.fetch(:data, {})
    data = data.merge(controller: "autogrow", action: "input->autogrow#grow") if autogrow
    rule = @template.tag.div(@template.tag.span("// #{label || rc_label(method)} //"), class: "console-rule")
    area = text_area(method, options.merge(rows: rows, data: data, class: rc_class("rc-textarea", options[:class])))
    note = [hint.presence, rc_errors(method)].compact
    @template.safe_join([rule, area, (@template.tag.p(@template.safe_join(note, " "), class: "rc-sub") if note.any?)].compact)
  end

  private

  def rc_field(method, label:, hint:)
    @template.tag.div(class: "console-status-row rc-field") do
      label(method, label || rc_label(method), class: "console-key") +
        @template.tag.span(class: "console-val") { @template.safe_join([yield, rc_hint(hint), rc_errors(method)].compact) }
    end
  end

  def rc_label(method)
    method.to_s.humanize.upcase
  end

  def rc_class(*parts)
    parts.compact.join(" ")
  end

  def rc_hint(hint)
    return if hint.blank?
    @template.tag.span(hint, class: "rc-hint")
  end

  # The field's own errors, plus the association's for a *_id select
  # (a belongs_to validates on :artist, the field is :artist_id).
  def rc_errors(method)
    return unless object.respond_to?(:errors)
    keys = [method]
    keys << method.to_s.delete_suffix("_id").to_sym if method.to_s.end_with?("_id")
    messages = keys.flat_map { |key| object.errors[key] }.uniq
    return if messages.empty?
    @template.tag.span(messages.join(", "), class: "rc-err")
  end
end
