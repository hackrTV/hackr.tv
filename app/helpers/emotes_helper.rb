module EmotesHelper
  # Inline JSON payload for the emote-picker Stimulus controller on the
  # Uplink + WIRE composers: [{slug:, url:, width:, height:}, ...] for every
  # chat-ready emote. Same cached map the renderers use, so previews and
  # rendered packets always agree on the image URL and box.
  def emote_picker_payload
    Emote.render_map.map { |slug, attrs| {slug: slug, **attrs} }
  end

  # The inline emote image the text renderers emit for ":slug:", for the
  # places that show an emote outside rendered text (reaction chips, the
  # reaction picker). `emote` is an Emote.render_map entry: the width and
  # height attrs reserve the right box before the image loads.
  def emote_image_tag(slug, emote)
    token = ":#{slug}:"
    tag.img(src: emote[:url], alt: token, title: token, class: "emote",
      width: emote[:width], height: emote[:height], loading: "eager")
  end
end
