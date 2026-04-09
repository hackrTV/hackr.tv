class MiningTickJob < ApplicationJob
  queue_as :default

  def perform
    Grid::MiningService.tick!
  end
end
