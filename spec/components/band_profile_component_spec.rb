require "rails_helper"

RSpec.describe BandProfileComponent, type: :component do
  include ViewComponent::TestHelpers

  let(:artist) { create(:artist, name: "Test Artist", slug: "test_artist") }
  let(:release) { create(:release, artist: artist, name: "Test Release") }
  let(:track) { create(:track, artist: artist, release: release, title: "Test Track") }
  let(:tracks) { [track] }

  let(:color_scheme) do
    {
      primary: "#00ff00",
      border: "#00ff00",
      legend: "#00ff00",
      background: "#0a0a0a",
      button: "#00ff00",
      button_text: "#000",
      back_button: "#222",
      back_border: "#444"
    }
  end

  describe "rendering" do
    it "renders the artist name in legend" do
      render_inline(described_class.new(artist: artist, tracks: tracks, color_scheme: color_scheme))

      expect(rendered_content).to include("TEST ARTIST")
    end

    it "uses the border color from color scheme" do
      render_inline(described_class.new(artist: artist, tracks: tracks, color_scheme: color_scheme))

      expect(rendered_content).to include("border: 2px solid #00ff00")
    end

    it "uses default filter_name based on artist name" do
      component = described_class.new(artist: artist, tracks: tracks, color_scheme: color_scheme)

      expect(component.filter_name).to eq("test artist")
    end

    it "accepts custom filter_name" do
      component = described_class.new(
        artist: artist,
        tracks: tracks,
        color_scheme: color_scheme,
        filter_name: "custom filter"
      )

      expect(component.filter_name).to eq("custom filter")
    end
  end

  describe "color scheme methods" do
    let(:component) do
      described_class.new(artist: artist, tracks: tracks, color_scheme: color_scheme)
    end

    it "returns border color from color scheme" do
      expect(component.border_color).to eq("#00ff00")
    end

    it "falls back to primary color for border if not specified" do
      color_scheme.delete(:border)
      expect(component.border_color).to eq("#00ff00")
    end

    it "returns legend color from color scheme" do
      expect(component.legend_color).to eq("#00ff00")
    end

    it "falls back to primary color for legend if not specified" do
      color_scheme.delete(:legend)
      expect(component.legend_color).to eq("#00ff00")
    end

    it "returns solid background style" do
      expect(component.background_style).to eq("background: #0a0a0a;")
    end

    it "returns gradient background style when specified" do
      color_scheme[:background_gradient] = "linear-gradient(90deg, #000, #fff)"
      expect(component.background_style).to eq("background: linear-gradient(90deg, #000, #fff);")
    end

    it "returns solid button style" do
      expected = "background: #00ff00; color: #000; font-weight: bold;"
      expect(component.button_style).to eq(expected)
    end

    it "returns gradient button style when specified" do
      color_scheme[:button_gradient] = "linear-gradient(90deg, #00ff00, #0000ff)"
      expected = "background: linear-gradient(90deg, #00ff00, #0000ff); color: white; font-weight: bold; border: none;"
      expect(component.button_style).to eq(expected)
    end
  end

  describe "slots" do
    it "renders intro slot content" do
      render_inline(described_class.new(artist: artist, tracks: tracks, color_scheme: color_scheme)) do |component|
        component.with_intro { "<p>Test Intro</p>".html_safe }
      end

      expect(rendered_content).to include("Test Intro")
    end

    it "renders release_section slot content" do
      render_inline(described_class.new(artist: artist, tracks: tracks, color_scheme: color_scheme)) do |component|
        component.with_release_section { "<p>Test Release Section</p>".html_safe }
      end

      expect(rendered_content).to include("Test Release Section")
    end

    it "renders philosophy_section slot content" do
      render_inline(described_class.new(artist: artist, tracks: tracks, color_scheme: color_scheme)) do |component|
        component.with_philosophy_section { "<p>Test Philosophy</p>".html_safe }
      end

      expect(rendered_content).to include("Test Philosophy")
    end
  end

  describe "navigation links" do
    it "includes back to bands link" do
      render_inline(described_class.new(artist: artist, tracks: tracks, color_scheme: color_scheme))

      expect(rendered_content).to include("← BACK TO BANDS")
    end

    it "includes pulse vault link with filter" do
      render_inline(described_class.new(
        artist: artist,
        tracks: tracks,
        color_scheme: color_scheme,
        filter_name: "test artist"
      ))

      expect(rendered_content).to include("LISTEN IN THE PULSE VAULT →")
    end
  end
end
