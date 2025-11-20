class CodexEntry < ApplicationRecord
  ENTRY_TYPES = %w[person organization event location technology faction item].freeze

  # Validations
  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true, format: {with: /\A[a-z0-9-]+\z/, message: "must be lowercase alphanumeric with hyphens"}
  validates :entry_type, presence: true, inclusion: {in: ENTRY_TYPES}
  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}, allow_nil: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :published, -> { where(published: true) }
  scope :by_type, ->(type) { where(entry_type: type) }
  scope :ordered, -> { order(position: :asc, name: :asc) }

  # Instance methods
  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-").strip
  end
end
