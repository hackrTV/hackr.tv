# frozen_string_literal: true

class ShopRotationJob < ApplicationJob
  queue_as :default

  def perform
    mob_ids = GridShopListing.in_rotation_pool.distinct.pluck(:grid_mob_id)

    mob_ids.each do |mob_id|
      mob = GridMob.find_by(id: mob_id)
      next unless mob&.vendor?

      Grid::ShopService.rotate!(mob)
    end
  end
end
