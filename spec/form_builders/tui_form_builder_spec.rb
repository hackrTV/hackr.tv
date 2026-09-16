require "rails_helper"

RSpec.describe TuiFormBuilder do
  let(:template) do
    ActionView::Base.empty.tap do |t|
      t.extend(ActionView::Helpers::FormHelper)
      t.extend(ActionView::Helpers::FormOptionsHelper)
    end
  end
  let(:artist) { Artist.new(name: "XERAEN") }
  let(:builder) { described_class.new(:artist, artist, template, {}) }

  describe "field helpers" do
    it "renders label, wrapper, and tui-input" do
      html = Capybara.string(builder.tui_text_field(:name))
      expect(html).to have_css("div.tui-field label.tui-field-label", text: "NAME")
      expect(html).to have_css("div.tui-field input.tui-input[name='artist[name]'][value='XERAEN']")
    end

    it "uppercases multi-word default labels" do
      html = Capybara.string(builder.tui_text_field(:created_at))
      expect(html).to have_css("label.tui-field-label", text: "CREATED AT")
    end

    it "honors an explicit label" do
      html = Capybara.string(builder.tui_text_field(:name, label: "DISPLAY NAME"))
      expect(html).to have_css("label.tui-field-label", text: "DISPLAY NAME")
    end

    it "renders a hint" do
      html = Capybara.string(builder.tui_text_field(:name, hint: "shown on the grid"))
      expect(html).to have_css("small.tui-field-hint", text: "shown on the grid")
    end

    it "passes extra options to the input" do
      html = Capybara.string(builder.tui_text_area(:name, rows: 4, style: "height: 80px;"))
      expect(html).to have_css("textarea.tui-input[rows='4'][style='height: 80px;']")
    end

    it "renders inline errors" do
      artist.errors.add(:name, "can't be blank")
      html = Capybara.string(builder.tui_text_field(:name))
      expect(html).to have_css("small.tui-field-error", text: "can't be blank")
    end
  end

  describe "#tui_select" do
    it "renders choices with select options and html options" do
      html = Capybara.string(builder.tui_select(:name, [%w[One one], %w[Two two]], {include_blank: "Select..."}, style: "width: 50%;"))
      expect(html).to have_css("div.tui-field select.tui-input[style='width: 50%;']")
      expect(html).to have_css("option", text: "Select...")
      expect(html).to have_css("option[value='two']", text: "Two")
    end
  end

  describe "#tui_check_box" do
    it "wraps the box inside the label" do
      html = Capybara.string(builder.tui_check_box(:name, label: "ACTIVE"))
      expect(html).to have_css("div.tui-field.tui-field--check label.tui-field-label input[type='checkbox']")
      expect(html).to have_css("label.tui-field-label", text: "ACTIVE")
    end
  end
end
