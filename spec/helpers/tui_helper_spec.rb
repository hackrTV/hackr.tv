require "rails_helper"

RSpec.describe TuiHelper, type: :helper do
  describe "#tui_button_classes" do
    it "returns the bare class with no color" do
      expect(helper.tui_button_classes).to eq("tui-button")
    end

    it "appends the -168 color class" do
      expect(helper.tui_button_classes(:green)).to eq("tui-button green-168")
    end

    it "accepts string colors" do
      expect(helper.tui_button_classes("purple")).to eq("tui-button purple-168")
    end

    it "merges extra classes after the color" do
      expect(helper.tui_button_classes(:red, "yield-destroy-btn")).to eq("tui-button red-168 yield-destroy-btn")
    end

    it "raises on unknown colors" do
      expect { helper.tui_button_classes(:magenta) }.to raise_error(ArgumentError, /magenta/)
    end
  end

  describe "#tui_button" do
    it "renders a link when a url is given" do
      html = helper.tui_button("LOG IN", "/grid/login", color: :green)
      expect(html).to have_css("a.tui-button.green-168[href='/grid/login']", text: "LOG IN")
    end

    it "renders a button element without a url" do
      html = helper.tui_button("FILTER", color: :cyan, type: "submit")
      expect(html).to have_css("button.tui-button.cyan-168[type='submit']", text: "FILTER")
    end

    it "passes through data, style, and extra classes" do
      html = helper.tui_button("PLAY", class: "playlist-info__play", data: {action: "track-list#playAll"}, style: "padding: 2px;")
      expect(html).to have_css("button.tui-button.playlist-info__play[data-action='track-list#playAll'][style='padding: 2px;']", text: "PLAY")
    end

    it "renders block content inside a link when first arg is the url" do
      html = helper.tui_button("/vault", color: :purple) { helper.tag.span("VAULT") }
      expect(html).to have_css("a.tui-button.purple-168[href='/vault'] span", text: "VAULT")
    end

    it "renders block content inside a button with no url" do
      html = helper.tui_button { helper.tag.span("×") }
      expect(html).to have_css("button.tui-button span", text: "×")
    end
  end

  describe "#tui_button_to" do
    it "renders a form-wrapped button" do
      html = helper.tui_button_to("DELETE", "/admin/redirects/1", color: :red, method: :delete)
      expect(html).to have_css("form[action='/admin/redirects/1'] button.tui-button.red-168", text: "DELETE")
    end
  end

  describe "#tui_submit" do
    it "renders a submit input via submit_tag" do
      html = helper.tui_submit("CONNECT", color: :purple)
      expect(html).to have_css("input[type='submit'][value='CONNECT'].tui-button.purple-168")
    end

    it "renders through a form builder when form: is given" do
      builder = ActionView::Helpers::FormBuilder.new(:hackr, nil, helper, {})
      html = helper.tui_submit("SAVE", form: builder, color: :green)
      expect(html).to have_css("input[type='submit'][value='SAVE'].tui-button.green-168")
    end
  end
end
