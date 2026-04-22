# frozen_string_literal: true

module Grid
  # Parses an optional leading quantity token from a command argument string.
  #
  # Examples:
  #   Grid::QuantityParser.parse("5 scrap metal")    → ParseResult(quantity: 5, remainder: "scrap metal")
  #   Grid::QuantityParser.parse("all scrap metal")  → ParseResult(quantity: :all, remainder: "scrap metal")
  #   Grid::QuantityParser.parse("scrap metal")      → ParseResult(quantity: 1, remainder: "scrap metal")
  #   Grid::QuantityParser.parse("")                  → ParseResult(quantity: 1, remainder: "")
  module QuantityParser
    ParseResult = Data.define(:quantity, :remainder)

    module_function

    def parse(raw)
      raw = raw.to_s.strip
      case raw
      when /\A(\d+)\s+(.+)\z/
        qty = $1.to_i
        qty = 1 if qty < 1
        ParseResult.new(quantity: qty, remainder: $2)
      when /\Aall\s+(.+)\z/i
        ParseResult.new(quantity: :all, remainder: $1)
      else
        ParseResult.new(quantity: 1, remainder: raw)
      end
    end
  end
end
