# frozen_string_literal: true

# Trailing edge of Uplink::MembersBroadcaster's debounce: re-render the
# channel's roster once for everyone on the shell.
module Uplink
  class MembersBroadcastJob < ApplicationJob
    queue_as :default

    def perform(channel_id)
      MembersBroadcaster.release(channel_id)
      channel = ChatChannel.find_by(id: channel_id)
      return unless channel

      MembersBroadcaster.broadcast(channel)
    end
  end
end
