# frozen_string_literal: true

class BandProfileComponent < ViewComponent::Base
  renders_one :intro
  renders_one :album_section
  renders_one :philosophy_section

  def initialize(artist:, tracks:, color_scheme:, filter_name: nil)
    @artist = artist
    @tracks = tracks
    @color_scheme = color_scheme
    @filter_name = filter_name || artist.name.downcase
  end

  attr_reader :artist, :tracks, :color_scheme, :filter_name

  def border_color
    color_scheme[:border] || color_scheme[:primary]
  end

  def legend_color
    color_scheme[:legend] || color_scheme[:primary]
  end

  def background_style
    if color_scheme[:background_gradient]
      "background: #{color_scheme[:background_gradient]};"
    else
      "background: #{color_scheme[:background] || "#0a0a0a"};"
    end
  end

  def button_style
    if color_scheme[:button_gradient]
      "background: #{color_scheme[:button_gradient]}; color: white; font-weight: bold; border: none;"
    else
      "background: #{color_scheme[:button] || color_scheme[:primary]}; color: #{color_scheme[:button_text] || "white"}; font-weight: bold;"
    end
  end
end
