# == Schema Information
#
# Table name: grid_mobs
# Database name: primary
#
#  id              :integer          not null, primary key
#  description     :text
#  dialogue_tree   :json
#  mob_type        :string
#  name            :string
#  vendor_config   :json
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  grid_faction_id :integer
#  grid_room_id    :integer
#
class GridMob < ApplicationRecord
  has_paper_trail

  MAX_DIALOGUE_DEPTH = 100

  belongs_to :grid_room
  belongs_to :grid_faction, optional: true
  has_many :grid_shop_listings, dependent: :destroy
  has_many :grid_shop_transactions, dependent: :nullify
  # When a giver mob is deleted, the missions lose their giver (FK nullified
  # at the DB level). Missions are world data — an admin can reassign.
  has_many :given_missions, class_name: "GridMission", foreign_key: :giver_mob_id, dependent: :nullify
  has_one_attached :avatar

  validates :name, presence: true
  validates :mob_type, inclusion: {in: %w[quest_giver vendor lore special], allow_nil: true}
  validate :faction_not_aggregate
  validate :avatar_file_valid, if: -> { avatar.attached? && avatar.blob&.new_record? }
  validate :dialogue_tree_depth_within_limit
  validate :dialogue_tree_keys_unique

  before_validation :normalize_dialogue_tree

  def avatar_panel
    avatar.variant(resize_to_fill: [180, 180], format: :webp, saver: {quality: 85})
  end

  def vendor?
    mob_type == "vendor"
  end

  def quest_giver?
    mob_type == "quest_giver"
  end

  def shop_type
    vendor_config&.dig("shop_type") || "standard"
  end

  def black_market?
    shop_type == "black_market"
  end

  def restock_interval_hours
    vendor_config&.dig("restock_interval_hours") || 24
  end

  def rotation_count
    vendor_config&.dig("rotation_count") || 3
  end

  private

  AVATAR_CONTENT_TYPES = %w[image/jpeg image/png image/webp].freeze
  AVATAR_MAX_SIZE = 5.megabytes

  def avatar_file_valid
    blob = avatar.blob
    unless AVATAR_CONTENT_TYPES.include?(blob.content_type)
      errors.add(:avatar, "must be a JPEG, PNG, or WebP image")
    end
    if blob.byte_size > AVATAR_MAX_SIZE
      errors.add(:avatar, "must be less than 5 MB")
    end
  end

  # Upgrade flat dialogue format (topic: "string") to nested format
  # (topic: { response: "string" }) so all downstream code can assume
  # the canonical shape.
  def normalize_dialogue_tree
    return if dialogue_tree.blank?
    tree = dialogue_tree
    return unless tree.is_a?(Hash) && tree["topics"].is_a?(Hash)

    tree["topics"] = normalize_topics_recursive(tree["topics"])
    self.dialogue_tree = tree
  rescue JSON::NestingError
    errors.add(:dialogue_tree, "is too deeply nested")
  end

  def normalize_topics_recursive(topics)
    return {} unless topics.is_a?(Hash)

    topics.transform_values do |value|
      case value
      when String
        {"response" => value}
      when Hash
        if value["topics"].is_a?(Hash)
          value.merge("topics" => normalize_topics_recursive(value["topics"]))
        else
          value
        end
      else
        {"response" => value.to_s}
      end
    end
  end

  def dialogue_tree_depth_within_limit
    return if errors[:dialogue_tree].any? # normalizer already caught nesting error
    return if dialogue_tree.blank?
    return unless dialogue_tree.is_a?(Hash) && dialogue_tree["topics"].is_a?(Hash)

    depth = measure_topic_depth(dialogue_tree["topics"])
    if depth > MAX_DIALOGUE_DEPTH
      errors.add(:dialogue_tree, "exceeds maximum depth of #{MAX_DIALOGUE_DEPTH} levels")
    end
  rescue JSON::NestingError
    errors.add(:dialogue_tree, "is too deeply nested") unless errors[:dialogue_tree].any?
  end

  def measure_topic_depth(topics, current = 1)
    return current unless topics.is_a?(Hash)

    max = current
    topics.each_value do |value|
      next unless value.is_a?(Hash) && value["topics"].is_a?(Hash)
      sub_depth = measure_topic_depth(value["topics"], current + 1)
      max = sub_depth if sub_depth > max
    end
    max
  end

  def dialogue_tree_keys_unique
    return if errors[:dialogue_tree].any?
    return if dialogue_tree.blank?
    return unless dialogue_tree.is_a?(Hash) && dialogue_tree["topics"].is_a?(Hash)

    seen = {}
    collect_topic_keys(dialogue_tree["topics"], [], seen)
    dupes = seen.select { |_key, paths| paths.length > 1 }
    dupes.each do |key, paths|
      locations = paths.map { |p| p.empty? ? "root" : p.join(" > ") }
      errors.add(:dialogue_tree, "has duplicate topic key '#{key}' at: #{locations.join(", ")}")
    end
  end

  def collect_topic_keys(topics, path, seen)
    return unless topics.is_a?(Hash)

    topics.each_key do |key|
      normalized = key.downcase
      seen[normalized] ||= []
      seen[normalized] << path.dup
      sub = topics[key]
      if sub.is_a?(Hash) && sub["topics"].is_a?(Hash)
        collect_topic_keys(sub["topics"], path + [key], seen)
      end
    end
  end

  # NPC/vendor rep hooks call ReputationService#adjust! on the mob's faction;
  # aggregate factions refuse direct writes. Block the misconfiguration at
  # write time so bad YAML seeds or admin edits surface immediately instead
  # of silently skipping rep in the command path.
  def faction_not_aggregate
    return unless grid_faction&.aggregate?
    errors.add(:grid_faction,
      "'#{grid_faction.display_name}' is an aggregate (derived from rep-links); " \
      "assign a source faction instead")
  end
end
