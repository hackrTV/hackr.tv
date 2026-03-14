# == Schema Information
#
# Table name: code_repositories
# Database name: primary
#
#  id               :integer          not null, primary key
#  default_branch   :string
#  description      :text
#  full_name        :string           not null
#  github_pushed_at :datetime
#  homepage         :string
#  language         :string
#  last_synced_at   :datetime
#  name             :string           not null
#  size_kb          :integer          default(0)
#  slug             :string           not null
#  stargazers_count :integer          default(0)
#  sync_error       :text
#  sync_status      :string
#  visible          :boolean          default(TRUE), not null
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  github_id        :integer          not null
#
# Indexes
#
#  index_code_repositories_on_github_id  (github_id) UNIQUE
#  index_code_repositories_on_slug       (slug) UNIQUE
#  index_code_repositories_on_visible    (visible)
#
class CodeRepository < ApplicationRecord
  # Validations
  validates :name, presence: true
  validates :full_name, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :github_id, presence: true, uniqueness: true

  # Callbacks
  before_validation :generate_slug, if: -> { slug.blank? && name.present? }

  # Scopes
  scope :visible, -> { where(visible: true) }
  scope :synced, -> { where.not(last_synced_at: nil) }
  scope :ordered, -> { order(stargazers_count: :desc, name: :asc) }
  scope :browsable, -> { visible.synced.ordered }

  def bare_repo_path
    Rails.root.join("storage", "repos", "#{slug}.git")
  end

  def cloned?
    Dir.exist?(bare_repo_path)
  end

  def to_param
    slug
  end

  private

  def generate_slug
    self.slug = name.downcase.gsub(/[^a-z0-9\s-]/, "").gsub(/\s+/, "-").squeeze("-").strip
  end
end
