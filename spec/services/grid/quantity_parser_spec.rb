# frozen_string_literal: true

require "rails_helper"

RSpec.describe Grid::QuantityParser do
  describe ".parse" do
    it "parses a leading integer" do
      result = described_class.parse("5 scrap metal")
      expect(result.quantity).to eq(5)
      expect(result.remainder).to eq("scrap metal")
    end

    it "parses 'all' keyword (case-insensitive)" do
      result = described_class.parse("All Cipher Chip")
      expect(result.quantity).to eq(:all)
      expect(result.remainder).to eq("Cipher Chip")
    end

    it "defaults to 1 when no quantity prefix" do
      result = described_class.parse("scrap metal")
      expect(result.quantity).to eq(1)
      expect(result.remainder).to eq("scrap metal")
    end

    it "handles single-word item name" do
      result = described_class.parse("3 scrap")
      expect(result.quantity).to eq(3)
      expect(result.remainder).to eq("scrap")
    end

    it "treats zero as 1" do
      result = described_class.parse("0 scrap")
      expect(result.quantity).to eq(1)
      expect(result.remainder).to eq("scrap")
    end

    it "treats negative as part of item name" do
      result = described_class.parse("-1 scrap")
      expect(result.quantity).to eq(1)
      expect(result.remainder).to eq("-1 scrap")
    end

    it "treats a bare number without item name as remainder" do
      result = described_class.parse("5")
      expect(result.quantity).to eq(1)
      expect(result.remainder).to eq("5")
    end

    it "treats bare 'all' without item name as remainder" do
      result = described_class.parse("all")
      expect(result.quantity).to eq(1)
      expect(result.remainder).to eq("all")
    end

    it "handles empty string" do
      result = described_class.parse("")
      expect(result.quantity).to eq(1)
      expect(result.remainder).to eq("")
    end

    it "handles nil" do
      result = described_class.parse(nil)
      expect(result.quantity).to eq(1)
      expect(result.remainder).to eq("")
    end

    it "preserves case of remainder" do
      result = described_class.parse("3 Signal Fragment")
      expect(result.remainder).to eq("Signal Fragment")
    end

    it "does not parse 'all' mid-string as quantity" do
      result = described_class.parse("recall chip")
      expect(result.quantity).to eq(1)
      expect(result.remainder).to eq("recall chip")
    end
  end
end
