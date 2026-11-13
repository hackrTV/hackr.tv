module BandsHelper
  # The roster blurb; {year} in a description is the lore year.
  def band_description(artist)
    (artist.description.presence || "Broadcasting truth through sound.")
      .gsub("{year}", (Date.current.year + 100).to_s)
  end
end
