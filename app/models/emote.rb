# == Schema Information
#
# Table name: emotes
# Database name: primary
#
#  id         :integer          not null, primary key
#  enabled    :boolean          default(TRUE), not null
#  slug       :string           not null
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_emotes_on_slug  (slug) UNIQUE
#
# Admin-managed chat emote: a slug + image rendered inline wherever the
# WireTextRenderer family renders user text (Uplink packets, WIRE pulses)
# when the text contains ":slug:". Storage and every JSON payload keep the
# raw token — substitution happens only at HTML render time, so relay,
# synthia and /terminal see plain text.
#
# Image serving: GIFs are served as the original blob (a variant would
# flatten the animation); PNG/WebP get a WebP variant shrunk to fit
# VARIANT_LIMIT (2x of the 28px CSS height, up to 4:1 wide). Any aspect
# ratio works, nothing is cropped: the <img> width/height come from the
# blob's analyzed metadata (chat_size) so wide FrankerFaceZ-style emotes
# reserve the right box before they load. URLs are built with path helpers,
# not url_for, because
# the Turbo broadcast callbacks render packet/pulse partials with no
# request context. Signed Active Storage URLs never expire here (no
# urls_expire_in), so already-broadcast chat HTML keeps working.
class Emote < ApplicationRecord
  has_paper_trail
  has_one_attached :image

  SLUG_FORMAT = /\A[a-z0-9_]+\z/
  IMAGE_CONTENT_TYPES = %w[image/png image/gif image/webp].freeze
  IMAGE_MAX_SIZE = 512.kilobytes
  CHAT_HEIGHT = 28 # px, matches .emote in emotes.css
  CHAT_MAX_WIDTH = 112 # 4:1; CSS object-fit letterboxes anything wider
  VARIANT_LIMIT = [CHAT_MAX_WIDTH * 2, CHAT_HEIGHT * 2].freeze # 2x for hi-dpi
  RENDER_MAP_CACHE_KEY = "emotes/render_map/v2"
  RENDER_MAP_TTL = 10.minutes

  scope :enabled, -> { where(enabled: true) }
  # Rows that can actually render: enabled with an attached image.
  scope :chat_ready, -> { enabled.where.associated(:image_attachment).with_attached_image.order(:slug) }

  before_validation :normalize_slug

  validates :slug, presence: true, uniqueness: true, length: {in: 2..32},
    format: {with: SLUG_FORMAT, message: "may only contain a-z, 0-9 and _"}
  validate :slug_has_letter
  validates :image, presence: true, on: :create
  validate :image_file_valid, if: -> { image.attached? && image.blob&.new_record? }

  # Attach/purge touch the record, so every image change lands here too.
  after_commit { self.class.expire_render_map }

  # {"slug" => {url:, width:, height:}} for every chat-ready emote.
  # Cached: renderers fetch it once per render, the composers once per page.
  # Width/height need the blob's image metadata, which Active Storage only
  # fills in from a background AnalyzeJob, so analyze inline if that has
  # not happened yet: a fresh upload never renders with guessed dimensions.
  def self.render_map
    Rails.cache.fetch(RENDER_MAP_CACHE_KEY, expires_in: RENDER_MAP_TTL, race_condition_ttl: 30.seconds) do
      chat_ready.to_h do |emote|
        emote.analyze_image
        [emote.slug, emote.chat_attrs]
      end
    end
  end

  def self.expire_render_map
    Rails.cache.delete(RENDER_MAP_CACHE_KEY)
  end

  # The persisted slug, not the in-memory one: a failed update with a bad
  # slug must keep the edit form posting to the record's real URL.
  def to_param = persisted? ? slug_in_database : nil

  def token = ":#{slug}:"

  def gif?
    image.attached? && image.content_type == "image/gif"
  end

  def chat_image
    gif? ? image : image.variant(resize_to_limit: VARIANT_LIMIT, format: :webp, saver: {quality: 85})
  end

  # Path (no host) usable from model callbacks and views alike.
  def chat_url
    helpers = Rails.application.routes.url_helpers
    if gif?
      helpers.rails_blob_path(image, only_path: true)
    else
      helpers.rails_representation_path(chat_image, only_path: true)
    end
  end

  # What the renderers and the picker need to lay the image out.
  def chat_attrs
    width, height = chat_size
    {url: chat_url, width: width, height: height}
  end

  # [width, height] at chat scale: CHAT_HEIGHT tall, aspect ratio kept,
  # width capped. Square fallback when the blob has no usable dimensions
  # (not analyzed yet, or analysis found none).
  def chat_size
    meta = image.attached? ? image.metadata : {}
    width = meta["width"].to_i
    height = meta["height"].to_i
    return [CHAT_HEIGHT, CHAT_HEIGHT] unless width > 0 && height > 0

    [(CHAT_HEIGHT * width / height.to_f).round.clamp(1, CHAT_MAX_WIDTH), CHAT_HEIGHT]
  end

  # Run Active Storage's image analysis now if AnalyzeJob has not yet.
  # A blob whose file is missing stays unanalyzed (chat_size falls back)
  # rather than taking every chat render down with it.
  def analyze_image
    return if !image.attached? || image.analyzed?
    image.analyze
  rescue ActiveStorage::FileNotFoundError, ActiveStorage::IntegrityError
    nil
  end

  private

  def normalize_slug
    self.slug = slug.to_s.strip.downcase.presence
  end

  # An all-digit slug like "30" would turn clock text (12:30:45) into an emote.
  def slug_has_letter
    return if slug.blank? || slug.match?(/[a-z]/)
    errors.add(:slug, "must contain at least one letter")
  end

  def image_file_valid
    blob = image.blob
    unless IMAGE_CONTENT_TYPES.include?(blob.content_type)
      errors.add(:image, "must be a PNG, GIF, or WebP image")
    end
    if blob.byte_size > IMAGE_MAX_SIZE
      errors.add(:image, "must be 512 KB or smaller")
    end
  end
end
