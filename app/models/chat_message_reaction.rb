# One hackr's reaction to one Uplink packet with one emote (Phase 2 item
# 7). Toggled by Uplink::ReactionsController; rendered as viewer-neutral
# chips under the packet (uplink/_reactions, grouped by emote with the
# reactors' callsign tokens so the reactions Stimulus controller can
# mark the viewer's own). Every create and destroy re-broadcasts the
# packet's chip row — the chips alone, not the row (uplink/_packet's
# hover state and grouping survive). Slugs reference emotes by name like
# packet text does; Emote deletes and renames follow.
# == Schema Information
#
# Table name: chat_message_reactions
# Database name: primary
#
#  id              :integer          not null, primary key
#  emote_slug      :string(32)       not null
#  created_at      :datetime         not null
#  chat_message_id :integer          not null
#  grid_hackr_id   :integer          not null
#
# Indexes
#
#  index_chat_message_reactions_on_grid_hackr_id  (grid_hackr_id)
#  index_chat_message_reactions_unique            (chat_message_id,grid_hackr_id,emote_slug) UNIQUE
#
# Foreign Keys
#
#  chat_message_id  (chat_message_id => chat_messages.id) ON DELETE => cascade
#  grid_hackr_id    (grid_hackr_id => grid_hackrs.id) ON DELETE => cascade
#
class ChatMessageReaction < ApplicationRecord
  belongs_to :chat_message
  belongs_to :grid_hackr

  validates :emote_slug, presence: true, length: {maximum: 32}, format: {with: Emote::SLUG_FORMAT}
  validates :grid_hackr_id, uniqueness: {scope: [:chat_message_id, :emote_slug]}

  # One callback for both (Rails keeps only the last after_*_commit
  # registered under one method name).
  after_commit :broadcast_reactions_html, on: [:create, :destroy]

  private

  def broadcast_reactions_html
    chat_message.broadcast_reactions_html
  end
end
