class LiveChatChannel < ApplicationCable::Channel
  # Thread-safe presence tracking (use Redis in production for multi-server)
  @@presence_counts = Hash.new(0)
  @@presence_mutex = Mutex.new

  def subscribed
    @channel_slug = params[:chat_channel]

    # Validate channel exists and is accessible
    chat_channel = ChatChannel.find_by(slug: @channel_slug)

    unless chat_channel
      Rails.logger.warn "=== LiveChatChannel: Invalid channel '#{@channel_slug}' ==="
      reject
      return
    end

    # Check if user is blackedout
    if current_hackr && UserPunishment.blackedout?(current_hackr)
      Rails.logger.warn "=== LiveChatChannel: Blackouted user #{current_hackr.hackr_alias} attempted to connect ==="
      reject
      return
    end

    # Check channel viewability (allows anonymous read-only access for livestream channels)
    unless chat_channel.viewable_by?(current_hackr)
      Rails.logger.warn "=== LiveChatChannel: #{current_hackr&.hackr_alias || "Anonymous"} cannot view channel #{@channel_slug} ==="
      reject
      return
    end

    Rails.logger.info "=== LiveChatChannel: #{current_hackr&.hackr_alias || "Anonymous"} subscribed to #{@channel_slug} ==="

    stream_from chat_channel.stream_name

    # Send recent packets on join
    send_recent_packets(chat_channel)

    # Track presence (count + economy presence)
    update_presence_count(chat_channel, 1)
    track_uplink_presence(chat_channel)
  end

  def unsubscribed
    if @channel_slug
      chat_channel = ChatChannel.find_by(slug: @channel_slug)
      if chat_channel
        Rails.logger.info "=== LiveChatChannel: #{current_hackr&.hackr_alias || "Anonymous"} disconnected from #{@channel_slug} ==="
        update_presence_count(chat_channel, -1)
        remove_uplink_presence(chat_channel)
      end
    end
  end

  def receive(data)
    # Handle ping for presence TTL refresh
    if data["type"] == "ping"
      chat_channel = ChatChannel.find_by(slug: @channel_slug)
      track_uplink_presence(chat_channel) if chat_channel
    end
  end

  private

  def send_recent_packets(chat_channel)
    recent_packets = chat_channel.chat_messages
      .active
      .recent
      .limit(20)
      .includes(:grid_hackr)

    # Send in chronological order (oldest first)
    packets_data = recent_packets.reverse.map do |message|
      {
        id: message.id,
        content: message.content,
        created_at: message.created_at.iso8601,
        dropped: message.dropped,
        grid_hackr: {
          id: message.grid_hackr_id,
          hackr_alias: message.grid_hackr&.hackr_alias,
          role: message.grid_hackr&.role
        },
        hackr_stream_id: message.hackr_stream_id,
        source: message.source
      }
    end

    # Get current presence count
    presence_count = @@presence_mutex.synchronize { @@presence_counts[@channel_slug] }

    transmit({
      type: "initial_packets",
      packets: packets_data,
      channel: @channel_slug,
      presence_count: presence_count
    })
  end

  def track_uplink_presence(chat_channel)
    return unless current_hackr
    GridUplinkPresence.touch!(current_hackr, chat_channel)
    current_hackr.touch_activity!
  rescue => e
    Rails.logger.error "=== LiveChatChannel: Presence tracking error: #{e.message} ==="
  end

  def remove_uplink_presence(chat_channel)
    return unless current_hackr
    GridUplinkPresence.remove!(current_hackr, chat_channel)
  rescue => e
    Rails.logger.error "=== LiveChatChannel: Presence removal error: #{e.message} ==="
  end

  def update_presence_count(chat_channel, delta)
    new_count = @@presence_mutex.synchronize do
      @@presence_counts[chat_channel.slug] = [@@presence_counts[chat_channel.slug] + delta, 0].max
      @@presence_counts[chat_channel.slug]
    end

    # Broadcast the actual count (not delta)
    ActionCable.server.broadcast(chat_channel.stream_name, {
      type: "presence_update",
      channel: chat_channel.slug,
      count: new_count
    })
  end
end
