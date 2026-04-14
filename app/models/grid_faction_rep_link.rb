# == Schema Information
#
# Table name: grid_faction_rep_links
# Database name: primary
#
#  id                :integer          not null, primary key
#  weight            :decimal(6, 3)    not null
#  created_at        :datetime         not null
#  updated_at        :datetime         not null
#  source_faction_id :integer          not null
#  target_faction_id :integer          not null
#
# Indexes
#
#  index_faction_rep_links_unique                     (source_faction_id,target_faction_id) UNIQUE
#  index_grid_faction_rep_links_on_source_faction_id  (source_faction_id)
#  index_grid_faction_rep_links_on_target_faction_id  (target_faction_id)
#
# Foreign Keys
#
#  source_faction_id  (source_faction_id => grid_factions.id)
#  target_faction_id  (target_faction_id => grid_factions.id)
#
class GridFactionRepLink < ApplicationRecord
  belongs_to :source_faction, class_name: "GridFaction", inverse_of: :outgoing_rep_links
  belongs_to :target_faction, class_name: "GridFaction", inverse_of: :incoming_rep_links

  validates :weight, presence: true, numericality: true
  validates :source_faction_id,
    uniqueness: {scope: :target_faction_id, message: "already has a link to this target"}
  validate :no_self_link
  validate :no_cycle

  private

  def no_self_link
    errors.add(:target_faction_id, "cannot equal source") if source_faction_id == target_faction_id
  end

  # Reject links that would close a cycle: DFS from `target` following outgoing
  # links; if we can reach `source`, the new edge would complete a loop. The
  # faction graph is small (≤ ~20 nodes), so no BFS/indexing optimisation needed.
  def no_cycle
    return if source_faction_id.blank? || target_faction_id.blank?
    return if source_faction_id == target_faction_id # caught by no_self_link

    stack = [target_faction_id]
    visited = Set.new
    until stack.empty?
      current = stack.pop
      next if visited.include?(current)
      visited << current

      if current == source_faction_id
        errors.add(:base, "link would create a cycle in the rep-link graph")
        return
      end

      outgoing = self.class.where(source_faction_id: current)
      outgoing = outgoing.where.not(id: id) if persisted?
      stack.concat(outgoing.pluck(:target_faction_id))
    end
  end
end
