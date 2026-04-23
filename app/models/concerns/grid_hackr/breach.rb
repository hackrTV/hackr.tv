# frozen_string_literal: true

module GridHackr::Breach
  extend ActiveSupport::Concern

  included do
    has_many :grid_hackr_breaches, dependent: :destroy
    belongs_to :zone_entry_room, class_name: "GridRoom", optional: true
  end

  def in_breach?
    grid_hackr_breaches.where(state: "active").exists?
  end

  def active_breach
    grid_hackr_breaches.where(state: "active")
      .includes(:grid_breach_template, :grid_breach_protocols)
      .first
  end

  def equipped_deck
    grid_items.equipped_by(self).find_by(equipped_slot: "deck")
  end

  # All software currently loaded into the equipped DECK
  def deck_software
    deck = equipped_deck
    return GridItem.none unless deck
    deck.loaded_software
  end
end
