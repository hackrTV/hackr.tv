# == Schema Information
#
# Table name: handbook_sections
# Database name: primary
#
#  id         :integer          not null, primary key
#  icon       :string
#  name       :string           not null
#  position   :integer          default(0), not null
#  published  :boolean          default(TRUE), not null
#  slug       :string           not null
#  summary    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_handbook_sections_on_published               (published)
#  index_handbook_sections_on_published_and_position  (published,position)
#  index_handbook_sections_on_slug                    (slug) UNIQUE
#
class HandbookSection < ApplicationRecord
  has_paper_trail

  has_many :articles,
    -> { ordered },
    class_name: "HandbookArticle",
    dependent: :destroy

  validates :name, presence: true
  validates :slug, presence: true, uniqueness: true,
    format: {with: /\A[a-z0-9-]+\z/, message: "must be lowercase alphanumeric with hyphens"}
  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(position: :asc, name: :asc) }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-").strip
  end
end
