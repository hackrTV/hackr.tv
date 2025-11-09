class HackrLog < ApplicationRecord
  belongs_to :author, class_name: "GridHackr"

  validates :title, presence: true
  validates :slug, presence: true, uniqueness: true
  validates :body, presence: true

  scope :published, -> { where(published: true) }
  scope :ordered, -> { order(published_at: :desc, created_at: :desc) }

  def to_param
    slug
  end

  def publish!
    update(published: true, published_at: Time.current) unless published?
  end

  def unpublish!
    update(published: false) if published?
  end
end
