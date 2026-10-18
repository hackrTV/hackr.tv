module EmotesHelper
  # Inline JSON payload for the emote-picker Stimulus controller on the
  # Uplink + WIRE composers: [{slug:, url:, width:, height:}, ...] for every
  # chat-ready emote. Same cached map the renderers use, so previews and
  # rendered packets always agree on the image URL and box.
  def emote_picker_payload
    Emote.render_map.map { |slug, attrs| {slug: slug, **attrs} }
  end
end
