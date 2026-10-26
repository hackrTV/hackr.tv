# == Schema Information
#
# Table name: chat_messages
# Database name: primary
#
#  id              :integer          not null, primary key
#  content         :text             not null
#  dropped         :boolean          default(FALSE), not null
#  dropped_at      :datetime
#  pinned_at       :datetime
#  source          :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#  chat_channel_id :integer          not null
#  grid_hackr_id   :integer          not null
#  hackr_stream_id :integer
#  pinned_by_id    :integer
#  reply_to_id     :integer
#
# Indexes
#
#  index_chat_messages_on_chat_channel_id                 (chat_channel_id)
#  index_chat_messages_on_chat_channel_id_and_created_at  (chat_channel_id,created_at)
#  index_chat_messages_on_dropped                         (dropped)
#  index_chat_messages_on_grid_hackr_id                   (grid_hackr_id)
#  index_chat_messages_on_hackr_stream_id                 (hackr_stream_id)
#  index_chat_messages_on_reply_to_id                     (reply_to_id)
#  index_chat_messages_pinned                             (chat_channel_id,pinned_at) WHERE pinned_at IS NOT NULL
#
# Foreign Keys
#
#  chat_channel_id  (chat_channel_id => chat_channels.id)
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id)
#  hackr_stream_id  (hackr_stream_id => hackr_streams.id)
#  pinned_by_id     (pinned_by_id => grid_hackrs.id) ON DELETE => nullify
#  reply_to_id      (reply_to_id => chat_messages.id) ON DELETE => nullify
#
class ChatMessage < ApplicationRecord
  include ProfanityFilterable

  belongs_to :chat_channel
  belongs_to :grid_hackr
  belongs_to :hackr_stream, optional: true
  # Replies (Phase 2 item 2): one quoted parent in the same channel. The
  # FK nulls the reference if the parent is hard-deleted; a *dropped*
  # parent stays referenced and the quote line renders [PACKET DROPPED].
  belongs_to :reply_to, class_name: "ChatMessage", optional: true, inverse_of: :replies
  has_many :replies, class_name: "ChatMessage", foreign_key: :reply_to_id, inverse_of: :reply_to
  # Channel pins (Phase 2 item 6): operator+ curation of any active packet.
  # The pinner's FK nulls if that hackr is hard-deleted; the pin stays.
  belongs_to :pinned_by, class_name: "GridHackr", optional: true

  validates :content, presence: true, length: {maximum: 512}
  validate :reply_to_in_channel
  filter_profanity :content

  MENTION_CAP = 5 # @mention toasts per packet
  REPLY_REFRESH_CAP = 20 # reply rows re-rendered when their parent is dropped/restored
  PIN_CAP = 50 # pinned packets per channel (Discord's limit)

  scope :active, -> { where(dropped: false) }
  scope :dropped, -> { where(dropped: true) }
  scope :pinned, -> { where.not(pinned_at: nil) }
  scope :recent, -> { order(created_at: :desc) }
  scope :for_channel, ->(channel) { where(chat_channel: channel) }

  # Dual-publish (Phase 5): the JSON broadcasts feed LiveChatChannel
  # subscribers (relay, synthia — external consumers, never retire);
  # the Turbo Stream broadcasts feed the Hotwire uplink pages on their
  # own stream name so HTML frames never reach JSON subscribers.
  after_create_commit :broadcast_new_packet
  after_create_commit :broadcast_new_packet_html
  after_create_commit :broadcast_bump
  after_create_commit :notify_mentions
  after_update_commit :broadcast_dropped_change, if: :saved_change_to_dropped?
  after_update_commit :broadcast_dropped_change_html, if: :saved_change_to_dropped?
  after_update_commit :broadcast_pinned_change_html, if: :saved_change_to_pinned_at?
  after_update_commit :broadcast_pins_count_html, if: :pins_count_changed?

  # Drop a message (moderation action)
  def drop!
    update(dropped: true, dropped_at: Time.current)
  end

  # Restore a dropped message
  def restore!
    update(dropped: false, dropped_at: nil)
  end

  def pinned?
    pinned_at.present?
  end

  # Pin / unpin (operator+ curation, Uplink::PacketsController). Plain
  # updates like drop!/restore!: the commit callbacks re-broadcast the row
  # (the .packet--pinned marker + the ◆ control flip) and the shell
  # header's pinned count.
  def pin!(by)
    update(pinned_at: Time.current, pinned_by: by)
  end

  def unpin!
    update(pinned_at: nil, pinned_by: nil)
  end

  # Hackrs this packet @mentions who may actually read it, in mention
  # order: resolved server-side and case-insensitively (the rendered
  # @alias links stay unvalidated, so the client never learns which
  # aliases exist), minus the author, service accounts (relay/synthia)
  # and anyone the channel is hidden from, capped at MENTION_CAP. The
  # lookup itself is bounded at twice the cap. Bridged packets count:
  # a Twitch viewer's "@xeraen" reaches XERAEN on /uplink.
  def mentioned_hackrs
    aliases = content.to_s.scan(UplinkTextRenderer::MENTION).map { |_, name| name.downcase }.uniq.first(MENTION_CAP * 2)
    return [] if aliases.empty?

    GridHackr.where("LOWER(hackr_alias) IN (?)", aliases)
      .where(service_account: false)
      .where.not(id: grid_hackr_id)
      .select { |hackr| chat_channel.viewable_by?(hackr) }
      .sort_by { |hackr| aliases.index(hackr.hackr_alias.downcase) }
      .first(MENTION_CAP)
  end

  private

  # One mention toast per recipient on their own [hackr, :toasts] stream
  # (the layout's #toast-region) — viewer-neutral by construction. Inline
  # like the other broadcasts: the test env has no job adapter.
  def notify_mentions
    mentioned_hackrs.each do |hackr|
      Turbo::StreamsChannel.broadcast_append_to(
        [hackr, :toasts],
        target: "toast-region",
        partial: "shared/toast_mention",
        locals: {packet: self}
      )
    end
  end

  # One tiny append per packet on the channel's ["uplink_bump", slug]
  # stream: every /uplink shell reading ANOTHER channel subscribes to it
  # and bumps that sidebar row's unread badge (no per-hackr fan-out; the
  # payload is an empty <i>, viewer-neutral by construction). Declared
  # before notify_mentions so the count lands before the toast recolors it.
  def broadcast_bump
    Turbo::StreamsChannel.broadcast_append_to(
      [Uplink::Unread::STREAM, chat_channel.slug],
      target: Uplink::Unread.bump_target(chat_channel.slug),
      html: "<i></i>"
    )
  end

  def broadcast_new_packet
    ActionCable.server.broadcast(chat_channel.stream_name, {
      type: "new_packet",
      packet: packet_json
    })
  end

  def broadcast_dropped_change
    if dropped?
      ActionCable.server.broadcast(chat_channel.stream_name, {
        type: "packet_dropped",
        packet_id: id
      })
    else
      ActionCable.server.broadcast(chat_channel.stream_name, {
        type: "packet_restored",
        packet_id: id,
        packet: packet_json
      })
    end
  end

  def broadcast_new_packet_html
    Turbo::StreamsChannel.broadcast_append_to(
      ["uplink_html", chat_channel.slug],
      target: "uplink-log",
      partial: "uplink/packet",
      locals: {packet: self, viewer: nil}
    )
  end

  # Drop and restore are both a whole-packet replace: the partial renders
  # the redacted or restored state from `dropped`, and per-viewer controls
  # re-reveal via the packet Stimulus controller on connect. Replies quote
  # this packet, so their rows are replaced too (newest REPLY_REFRESH_CAP)
  # and the quote flips to/from [PACKET DROPPED] live.
  def broadcast_dropped_change_html
    replace_packet_html(self)
    replies.active.includes(:grid_hackr).order(id: :desc).limit(REPLY_REFRESH_CAP).each do |reply|
      replace_packet_html(reply)
    end
  end

  # Pin/unpin: a whole-packet replace like drop/restore — the marker and
  # the hover control render from `pinned_at`.
  def broadcast_pinned_change_html
    replace_packet_html(self)
  end

  # The shell header's [◆] count is pinned *active* packets, so a pinned
  # packet dropping or coming back moves it too. Viewer-neutral (the count
  # is the same for everyone); the dock/popout have no #uplink-pins-count
  # and ignore the replace.
  def pins_count_changed?
    saved_change_to_pinned_at? || (pinned? && saved_change_to_dropped?)
  end

  def broadcast_pins_count_html
    Turbo::StreamsChannel.broadcast_replace_to(
      ["uplink_html", chat_channel.slug],
      target: "uplink-pins-count",
      partial: "uplink/pins_count",
      locals: {channel: chat_channel}
    )
  end

  def replace_packet_html(packet)
    Turbo::StreamsChannel.broadcast_replace_to(
      ["uplink_html", chat_channel.slug],
      target: ActionView::RecordIdentifier.dom_id(packet),
      partial: "uplink/packet",
      locals: {packet: packet, viewer: nil}
    )
  end

  # Same channel is the invariant; "parent not dropped" is checked only at
  # creation (Uplink::PacketsController) — a validation here would make
  # drop!/restore! fail on a reply once its parent was dropped.
  def reply_to_in_channel
    return unless reply_to && reply_to.chat_channel_id != chat_channel_id

    errors.add(:reply_to, "must be in the same channel")
  end

  def packet_json
    {
      id: id,
      content: content,
      created_at: created_at.iso8601,
      dropped: dropped,
      grid_hackr: {
        id: grid_hackr_id,
        hackr_alias: grid_hackr&.hackr_alias,
        role: grid_hackr&.role
      },
      hackr_stream_id: hackr_stream_id,
      source: source,
      reply_to_id: reply_to_id
    }
  end
end
