# == Schema Information
#
# Table name: handbook_articles
# Database name: primary
#
#  id                  :integer          not null, primary key
#  body                :text
#  difficulty          :string
#  kind                :string           default("reference"), not null
#  metadata            :json
#  position            :integer          default(0), not null
#  published           :boolean          default(TRUE), not null
#  slug                :string           not null
#  summary             :text
#  title               :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#  handbook_section_id :integer          not null
#
# Indexes
#
#  index_handbook_articles_on_handbook_section_id               (handbook_section_id)
#  index_handbook_articles_on_handbook_section_id_and_position  (handbook_section_id,position)
#  index_handbook_articles_on_kind                              (kind)
#  index_handbook_articles_on_published                         (published)
#  index_handbook_articles_on_slug                              (slug) UNIQUE
#
# Foreign Keys
#
#  handbook_section_id  (handbook_section_id => handbook_sections.id)
#
class HandbookArticle < ApplicationRecord
  has_paper_trail

  KINDS = %w[reference tutorial].freeze
  DIFFICULTIES = %w[beginner intermediate advanced].freeze

  belongs_to :handbook_section

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true,
    format: {with: /\A[a-z0-9-]+\z/, message: "must be lowercase alphanumeric with hyphens"}
  validates :kind, presence: true, inclusion: {in: KINDS}
  validates :difficulty, inclusion: {in: DIFFICULTIES}, allow_blank: true
  validates :position, numericality: {only_integer: true, greater_than_or_equal_to: 0}

  before_validation :generate_slug, if: -> { slug.blank? && title.present? }

  scope :published, -> { where(published: true) }
  # Visible to end users: article AND its section are both published. Use
  # this for any reader-facing lookup; use `published` alone only when the
  # section's visibility has already been enforced separately.
  scope :visible, -> {
    published.joins(:handbook_section).where(handbook_sections: {published: true})
  }
  scope :ordered, -> { order(position: :asc, title: :asc) }
  scope :tutorials, -> { where(kind: "tutorial") }
  scope :reference_kind, -> { where(kind: "reference") }
  scope :recently_updated, -> { order(updated_at: :desc) }

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = title.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-").strip
  end
end
