class Echo < ApplicationRecord
  self.table_name = "echoes"

  belongs_to :pulse, counter_cache: :echo_count
  belongs_to :grid_hackr

  validates :grid_hackr_id, uniqueness: {scope: :pulse_id, message: "has already echoed this pulse"}
  validates :echoed_at, presence: true

  before_validation :set_echoed_at, on: :create

  scope :recent, -> { order(echoed_at: :desc) }

  private

  def set_echoed_at
    self.echoed_at ||= Time.current
  end
end
