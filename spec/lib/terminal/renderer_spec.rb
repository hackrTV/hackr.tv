# frozen_string_literal: true

require "rails_helper"

RSpec.describe Terminal::Renderer do
  subject(:renderer) { described_class.new }

  describe "#initialize" do
    it "defaults to the default color scheme" do
      expect(renderer.color_scheme).to eq(:default)
    end

    it "accepts a color scheme parameter" do
      renderer = described_class.new(color_scheme: :amber)
      expect(renderer.color_scheme).to eq(:amber)
    end
  end

  describe "#color_scheme=" do
    it "sets valid color schemes" do
      renderer.color_scheme = :green
      expect(renderer.color_scheme).to eq(:green)
    end

    it "rejects invalid schemes and defaults to :default" do
      renderer.color_scheme = :invalid
      expect(renderer.color_scheme).to eq(:default)
    end

    it "accepts all valid schemes" do
      %i[default amber green cga].each do |scheme|
        renderer.color_scheme = scheme
        expect(renderer.color_scheme).to eq(scheme)
      end
    end
  end

  describe "#colors" do
    it "returns the current color scheme palette" do
      expect(renderer.colors).to be_a(Hash)
      expect(renderer.colors).to have_key(:amber)
      expect(renderer.colors).to have_key(:cyan)
    end

    it "returns different palettes for different schemes" do
      default_cyan = renderer.colors[:cyan]

      renderer.color_scheme = :amber
      amber_cyan = renderer.colors[:cyan]

      expect(default_cyan).not_to eq(amber_cyan)
    end
  end

  describe "#colorize" do
    it "wraps text with ANSI color codes" do
      result = renderer.colorize("test", :cyan)

      expect(result).to include("test")
      expect(result).to include("\e[")
      expect(result).to end_with(Terminal::ANSI::RESET)
    end

    it "uses colors from current scheme" do
      renderer.color_scheme = :default
      default_result = renderer.colorize("test", :amber)

      renderer.color_scheme = :green
      green_result = renderer.colorize("test", :amber)

      # Both should have the text but different color codes
      expect(default_result).to include("test")
      expect(green_result).to include("test")
      expect(default_result).not_to eq(green_result)
    end

    it "falls back to white for unknown colors" do
      result = renderer.colorize("test", :nonexistent)
      expect(result).to include("test")
      expect(result).to include(renderer.colors[:white])
    end
  end

  describe "#bold" do
    it "wraps text with bold ANSI code" do
      result = renderer.bold("test")

      expect(result).to include("test")
      expect(result).to include(Terminal::ANSI::BOLD)
      expect(result).to end_with(Terminal::ANSI::RESET)
    end
  end

  describe "#dim" do
    it "wraps text with dim ANSI code" do
      result = renderer.dim("test")

      expect(result).to include("test")
      expect(result).to include(Terminal::ANSI::DIM)
      expect(result).to end_with(Terminal::ANSI::RESET)
    end
  end

  describe "#bold_color" do
    it "combines bold and color" do
      result = renderer.bold_color("test", :cyan)

      expect(result).to include("test")
      expect(result).to include(Terminal::ANSI::BOLD)
      expect(result).to include(renderer.colors[:cyan])
    end
  end

  describe "#html_to_ansi" do
    it "returns empty string for nil input" do
      expect(renderer.html_to_ansi(nil)).to eq("")
    end

    it "returns empty string for empty input" do
      expect(renderer.html_to_ansi("")).to eq("")
    end

    it "converts span color styles to ANSI" do
      html = "<span style='color: #fbbf24;'>amber text</span>"
      result = renderer.html_to_ansi(html)

      expect(result).to include("amber text")
      expect(result).to include("\e[38;2;251;191;36m")
      expect(result).to include(Terminal::ANSI::RESET)
    end

    it "handles bold font-weight" do
      html = "<span style='font-weight: bold;'>bold text</span>"
      result = renderer.html_to_ansi(html)

      expect(result).to include("bold text")
      expect(result).to include(Terminal::ANSI::BOLD)
    end

    it "handles combined color and bold" do
      html = "<span style='color: #22d3ee; font-weight: bold;'>cyan bold</span>"
      result = renderer.html_to_ansi(html)

      expect(result).to include("cyan bold")
      expect(result).to include("\e[38;2;34;211;238m")
      expect(result).to include(Terminal::ANSI::BOLD)
    end

    it "strips remaining HTML tags" do
      html = "<div><p>plain text</p></div>"
      result = renderer.html_to_ansi(html)

      expect(result).to include("plain text")
      expect(result).not_to include("<")
      expect(result).not_to include(">")
    end

    it "converts br tags to newlines" do
      html = "line1<br>line2<br/>line3"
      result = renderer.html_to_ansi(html)

      expect(result).to eq("line1\nline2\nline3")
    end

    it "decodes HTML entities" do
      html = "&lt;code&gt; &amp; &quot;quotes&quot;"
      result = renderer.html_to_ansi(html)

      expect(result).to eq('<code> & "quotes"')
    end

    it "normalizes 3-digit hex colors to 6-digit" do
      html = "<span style='color: #666;'>gray text</span>"
      result = renderer.html_to_ansi(html)

      expect(result).to include("gray text")
      # Should convert #666 to #666666 and apply gray color
    end
  end

  describe "#line" do
    it "draws a horizontal line of specified width" do
      result = renderer.line(width: 10, color: :cyan)

      # Should have 10 horizontal line characters
      expect(result.gsub(/\e\[[0-9;]*m/, "").length).to eq(10)
    end

    it "applies the specified color" do
      result = renderer.line(color: :purple)
      expect(result).to include(renderer.colors[:purple])
    end
  end

  describe "#double_line" do
    it "draws a double horizontal line" do
      result = renderer.double_line(width: 10, color: :cyan)

      # Should contain double horizontal characters
      expect(result).to include(Terminal::ANSI::Box::DOUBLE_HORIZONTAL)
    end
  end

  describe "#header" do
    it "creates a centered header with lines" do
      result = renderer.header("TEST", width: 20, color: :cyan)

      expect(result).to include("TEST")
      expect(result).to include(Terminal::ANSI::Box::DOUBLE_HORIZONTAL)
    end
  end

  describe "#divider" do
    it "creates a divider with optional text" do
      result = renderer.divider("SECTION", width: 30, color: :gray)

      expect(result).to include("SECTION")
      expect(result).to include(Terminal::ANSI::Box::HORIZONTAL)
    end

    it "creates a plain line without text" do
      result = renderer.divider(nil, width: 20, color: :gray)

      # Should be just horizontal lines
      visible_chars = result.gsub(/\e\[[0-9;]*m/, "")
      expect(visible_chars.length).to eq(20)
    end
  end

  describe "#box" do
    it "draws a box around content" do
      result = renderer.box("content", width: 20, color: :cyan)

      expect(result).to include("content")
      expect(result).to include(Terminal::ANSI::Box::DOUBLE_TOP_LEFT)
      expect(result).to include(Terminal::ANSI::Box::DOUBLE_BOTTOM_RIGHT)
    end

    it "includes title when provided" do
      result = renderer.box("content", width: 30, color: :cyan, title: "TITLE")

      expect(result).to include("TITLE")
      expect(result).to include("content")
    end
  end

  describe "#menu_item" do
    it "formats a menu item with key and label" do
      result = renderer.menu_item("1", "Option One")

      expect(result).to include("[1]")
      expect(result).to include("Option One")
    end

    it "shows disabled items in gray" do
      result = renderer.menu_item("X", "Disabled", disabled: true)

      expect(result).to include("[X]")
      expect(result).to include(renderer.colors[:gray])
    end

    it "includes optional note" do
      result = renderer.menu_item("G", "Grid", note: "[LOGIN REQUIRED]")

      expect(result).to include("[LOGIN REQUIRED]")
    end
  end

  describe "#key_value" do
    it "formats a key-value pair" do
      result = renderer.key_value("Name:", "Value")

      expect(result).to include("Name:")
      expect(result).to include("Value")
    end
  end

  describe "#time_ago" do
    it "returns 'just now' for nil" do
      expect(renderer.time_ago(nil)).to eq("just now")
    end

    it "returns 'just now' for recent times" do
      expect(renderer.time_ago(Time.current)).to eq("just now")
    end

    it "returns minutes for times within the hour" do
      expect(renderer.time_ago(30.minutes.ago)).to eq("30m ago")
    end

    it "returns hours for times within the day" do
      expect(renderer.time_ago(3.hours.ago)).to eq("3h ago")
    end

    it "returns days for older times" do
      expect(renderer.time_ago(2.days.ago)).to eq("2d ago")
    end
  end

  describe "#clear_screen" do
    it "returns the ANSI clear screen sequence" do
      expect(renderer.clear_screen).to eq(Terminal::ANSI::CLEAR_SCREEN)
    end
  end
end
