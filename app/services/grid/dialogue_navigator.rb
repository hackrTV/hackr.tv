# frozen_string_literal: true

module Grid
  # Navigates branching dialogue trees stored as JSON on GridMob.
  #
  # Tree format:
  #   { "greeting" => "...",
  #     "topics"   => {
  #       "keyword" => {
  #         "response" => "...",
  #         "topics"   => { ... }  # optional sub-topics
  #       }
  #     }
  #   }
  #
  # The hackr's current position in each mob's tree is tracked in
  # stats["dialogue_context"] as { mob_id => [topic_key, ...] }.
  class DialogueNavigator
    RESET_ALIASES = %w[again reset start over].freeze
    BACK_ALIASES = %w[back up ..].freeze

    attr_reader :hackr, :mob

    def initialize(hackr:, mob:)
      @hackr = hackr
      @mob = mob
      @tree = mob.dialogue_tree || {}
    end

    # Current path from root (array of topic keys).
    def current_path
      hackr.dialogue_path_for(mob)
    end

    # Resolve the node (Hash) at a given path. Returns nil if path invalid.
    def node_at(path)
      node = @tree
      path.each do |key|
        topics = node.is_a?(Hash) ? node["topics"] : nil
        return nil unless topics.is_a?(Hash)
        node = topics[key]
        return nil unless node.is_a?(Hash)
      end
      node
    end

    # Available topic keys at the current path.
    def current_topics
      node = current_path.empty? ? @tree : node_at(current_path)
      return {} unless node.is_a?(Hash)
      node["topics"] || {}
    end

    # Navigate to a topic. Search order:
    #   1. Current depth — can advance context if topic has children
    #   2. Walk up ancestors — show response without moving context
    #   3. Global tree search — reach any topic in any branch
    # Only current-depth matches with children advance the context path.
    # Returns { response:, topics:, path: } on success, nil if not found.
    def navigate(topic_key)
      # 1. Current depth — match here can advance context
      result = find_topic_in(current_path, topic_key)
      if result
        new_path = current_path + [result[:key]]
        if self.class.has_children?(result[:node])
          hackr.set_dialogue_path(mob, new_path)
        end
        return build_result(result[:node], new_path)
      end

      # 2. Walk up ancestors — show response without moving context
      ancestor = current_path.dup
      while ancestor.any?
        ancestor.pop
        result = find_topic_in(ancestor, topic_key)
        return build_result(result[:node], ancestor + [result[:key]]) if result
      end

      # 3. Global search — any branch in the tree
      result = search_tree(@tree["topics"] || {}, topic_key, [])
      return build_result(result[:node], result[:path]) if result

      nil
    end

    # Go up one level. Returns the new path, or [] if already at root.
    def go_back
      path = current_path
      return [] if path.empty?

      new_path = path[0..-2]
      if new_path.empty?
        hackr.clear_dialogue_path(mob)
      else
        hackr.set_dialogue_path(mob, new_path)
      end
      new_path
    end

    # Reset to root. Clears dialogue context.
    def reset!
      hackr.clear_dialogue_path(mob)
    end

    # Whether the hackr has navigated into the tree (not at root).
    def at_root?
      current_path.empty?
    end

    # The greeting text (root level only).
    def greeting
      @tree["greeting"]
    end

    # Check if a given topic key is a reset alias.
    def self.reset_alias?(word)
      RESET_ALIASES.include?(word.to_s.downcase)
    end

    # Check if a given topic key is a back alias.
    def self.back_alias?(word)
      BACK_ALIASES.include?(word.to_s.downcase)
    end

    # Whether a topic node has sub-topics.
    def self.has_children?(topic_node)
      topic_node.is_a?(Hash) &&
        topic_node["topics"].is_a?(Hash) &&
        topic_node["topics"].any?
    end

    private

    # Look up a topic key in the topics at a given path.
    def find_topic_in(path, topic_key)
      node = path.empty? ? @tree : node_at(path)
      return nil unless node.is_a?(Hash)
      topics = node["topics"]
      return nil unless topics.is_a?(Hash)

      key = topics.key?(topic_key) ? topic_key :
            topics.keys.find { |k| k.downcase == topic_key.downcase }
      return nil unless key

      target = topics[key]
      return nil unless target.is_a?(Hash)

      {node: target, key: key}
    end

    # DFS search of the entire tree for a topic key.
    def search_tree(topics, topic_key, path)
      return nil unless topics.is_a?(Hash)

      topics.each do |k, v|
        next unless v.is_a?(Hash)
        # Check this node's children
        sub = v["topics"]
        next unless sub.is_a?(Hash)
        match = sub.key?(topic_key) ? topic_key :
                sub.keys.find { |sk| sk.downcase == topic_key.downcase }
        if match && sub[match].is_a?(Hash)
          return {node: sub[match], key: match, path: path + [k, match]}
        end
        # Recurse deeper
        result = search_tree(sub, topic_key, path + [k])
        return result if result
      end

      nil
    end

    def build_result(node, path)
      {
        response: node["response"],
        topics: node["topics"] || {},
        path: path
      }
    end
  end
end
