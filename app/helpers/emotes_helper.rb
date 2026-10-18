module EmotesHelper
  # Inline JSON payload for the emote-picker Stimulus controller on the
  # Uplink + WIRE composers: [{slug:, url:}, ...] for every chat-ready emote.
  # Same cached map the renderers use, so previews and rendered packets
  # always agree on the image URL.
  def emote_picker_payload
    Emote.render_map.map { |slug, url| {slug: slug, url: url} }
  end
end
