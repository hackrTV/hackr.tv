# == Schema Information
#
# Table name: grid_transactions
# Database name: primary
#
#  id               :integer          not null, primary key
#  amount           :integer          not null
#  memo             :string
#  previous_tx_hash :string
#  tx_hash          :string           not null
#  tx_type          :string           not null
#  created_at       :datetime         not null
#  from_cache_id    :integer          not null
#  to_cache_id      :integer          not null
#
# Indexes
#
#  index_grid_transactions_on_created_at     (created_at)
#  index_grid_transactions_on_from_cache_id  (from_cache_id)
#  index_grid_transactions_on_to_cache_id    (to_cache_id)
#  index_grid_transactions_on_tx_hash        (tx_hash) UNIQUE
#  index_grid_transactions_on_tx_type        (tx_type)
#
class GridTransaction < ApplicationRecord
  TX_TYPES = %w[transfer mining_reward gameplay_reward burn redemption genesis].freeze

  belongs_to :from_cache, class_name: "GridCache"
  belongs_to :to_cache, class_name: "GridCache"

  validates :amount, numericality: {only_integer: true, greater_than: 0}
  validates :tx_type, inclusion: {in: TX_TYPES}
  validates :tx_hash, presence: true, uniqueness: true

  scope :recent, -> { order(created_at: :desc, id: :desc) }
  scope :for_cache, ->(cache) { where(from_cache: cache).or(where(to_cache: cache)) }
  scope :by_type, ->(type) { where(tx_type: type) }

  # Immutable: prevent updates and deletes
  before_update { raise ActiveRecord::ReadOnlyRecord, "GridTransaction records are immutable" }
  before_destroy { raise ActiveRecord::ReadOnlyRecord, "GridTransaction records cannot be deleted" }

  def compute_hash
    data = [
      from_cache.address,
      to_cache.address,
      amount.to_s,
      tx_type,
      memo.to_s,
      created_at.iso8601(6),
      previous_tx_hash.to_s
    ].join(":")
    Digest::SHA256.hexdigest(data)
  end

  def short_hash
    tx_hash&.first(12)
  end
end
