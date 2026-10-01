require "rails_helper"

RSpec.describe TuiWindowComponent, type: :component do
  include ViewComponent::TestHelpers

  it "renders admin variant with legend, admin chrome, and default width" do
    render_inline(described_class.new(title: "/root/zones :: MANAGE", variant: :admin)) { "BODY" }

    expect(page).to have_css("div.tui-window.white-text.admin-panel.tui-window--page[style='max-width: 1400px']")
    expect(page).to have_css("fieldset.admin-panel-border legend.center", text: "/root/zones :: MANAGE")
    expect(page).to have_css("fieldset", text: "BODY")
  end

  it "renders panel variant without legend when title is nil" do
    render_inline(described_class.new) { "INNER" }

    expect(page).to have_css("div.tui-window.white-text.tui-window--panel", text: "INNER")
    expect(page).to have_no_css("legend")
    expect(page).to have_no_css("[style]")
  end

  it "renders page variant with explicit width" do
    render_inline(described_class.new(variant: :page, width: 900, title: "T"))

    expect(page).to have_css("div.tui-window--page[style='max-width: 900px']")
    expect(page).to have_no_css(".admin-panel")
  end

  it "applies color to window and fieldset border" do
    render_inline(described_class.new(color: :cyan, title: "C"))

    expect(page).to have_css("div.tui-window.cyan-168.white-text")
    expect(page).to have_css("fieldset.cyan-168-border")
  end

  it "passes through class, style, id, and data attributes" do
    render_inline(described_class.new(variant: :panel, class: "extra", style: "overflow-x: auto;",
      id: "zone-panel", data: {controller: "x"}))

    expect(page).to have_css("div#zone-panel.tui-window--panel.extra[data-controller='x'][style='overflow-x: auto;']")
  end

  it "merges width with passthrough style" do
    render_inline(described_class.new(variant: :admin, width: 900, style: "margin-top: 0;"))

    expect(page).to have_css("div[style='max-width: 900px; margin-top: 0;']")
  end

  it "honors legend_class and fieldset_class overrides" do
    render_inline(described_class.new(title: "L", legend_class: nil, fieldset_class: "tui-fieldset"))

    expect(page).to have_css("fieldset.tui-fieldset legend:not([class])", text: "L")
  end

  it "renders without a fieldset when fieldset: false" do
    render_inline(described_class.new(fieldset: false, style: "overflow-x: auto;")) { "TABLE" }

    expect(page).to have_css("div.tui-window--panel[style='overflow-x: auto;']", text: "TABLE")
    expect(page).to have_no_css("fieldset")
  end

  it "rejects title with fieldset: false" do
    expect { described_class.new(title: "T", fieldset: false) }.to raise_error(ArgumentError, /fieldset/)
  end

  it "rejects unknown variants and colors" do
    expect { described_class.new(variant: :modal) }.to raise_error(ArgumentError, /modal/)
    expect { described_class.new(color: :magenta) }.to raise_error(ArgumentError, /magenta/)
  end
end
