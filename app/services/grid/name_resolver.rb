# frozen_string_literal: true

module Grid
  # Resolves object names from user input with exact-match-first,
  # substring-fallback semantics.
  #
  # Examples:
  #   Grid::NameResolver.resolve(room.grid_mobs, "coord")
  #     → <GridMob name="Fracture Network Coordinator">
  #
  #   Grid::NameResolver.resolve(room.grid_mobs, "net")
  #     → raises AmbiguousMatch(["Network Node", "Net Crawler"])
  #
  #   Grid::NameResolver.resolve_key({"network" => {…}, "news" => {…}}, "ne")
  #     → raises AmbiguousMatch(["network", "news"])
  module NameResolver
    class AmbiguousMatch < StandardError
      attr_reader :candidates

      def initialize(candidates)
        @candidates = candidates
        super("Ambiguous match: #{candidates.join(", ")}")
      end
    end

    ALLOWED_COLUMNS = %w[name slug hackr_alias grid_item_definitions.name].freeze

    module_function

    # Resolve a name against an ActiveRecord scope.
    #
    # scope   — any AR relation (room.grid_mobs, hackr.grid_items, etc.)
    # input   — raw user-typed string
    # column: — SQL column expression (default "name"; pass "hackr_alias",
    #           "slug", or "grid_item_definitions.name" as needed)
    #
    # Returns the matching record or nil.
    # Raises AmbiguousMatch when multiple partial matches exist.
    def resolve(scope, input, column: "name")
      raise ArgumentError, "Column #{column.inspect} not in allowlist" unless ALLOWED_COLUMNS.include?(column)

      normalized = input.to_s.strip.downcase
      return nil if normalized.empty?

      # 1. Exact match — no ambiguity possible
      exact = scope.find_by("LOWER(#{column}) = ?", normalized)
      return exact if exact

      # 2. Substring fallback
      pattern = "%#{sanitize_like(normalized)}%"
      partials = scope.where("LOWER(#{column}) LIKE ? ESCAPE '\\'", pattern).to_a

      case partials.size
      when 0 then nil
      when 1 then partials.first
      else
        names = partials.map { |r| r.public_send(column_reader(column)) }
        raise AmbiguousMatch.new(names)
      end
    end

    # Resolve a Hash key by substring.
    #
    # hash  — Hash whose keys are topic/dialogue strings
    # input — raw user-typed string
    #
    # Returns { key:, value: } or nil.
    # Raises AmbiguousMatch when multiple partial matches exist.
    def resolve_key(hash, input)
      return nil unless hash.is_a?(Hash)

      normalized = input.to_s.strip.downcase
      return nil if normalized.empty?

      # 1. Exact match (case-insensitive)
      exact_key = hash.keys.find { |k| k.downcase == normalized }
      return {key: exact_key, value: hash[exact_key]} if exact_key

      # 2. Substring fallback
      matching = hash.keys.select { |k| k.downcase.include?(normalized) }

      case matching.size
      when 0 then nil
      when 1 then {key: matching.first, value: hash[matching.first]}
      else
        raise AmbiguousMatch.new(matching)
      end
    end

    # Escapes SQL LIKE metacharacters in user input.
    def sanitize_like(str)
      str.gsub(/[%_\\]/) { |c| "\\#{c}" }
    end
    private_class_method :sanitize_like

    # Derives the Ruby method name from a SQL column expression.
    # "name" → "name", "hackr_alias" → "hackr_alias",
    # "grid_item_definitions.name" → "name"
    def column_reader(column)
      column.to_s.split(".").last
    end
    private_class_method :column_reader
  end
end
