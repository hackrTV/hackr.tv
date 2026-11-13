class AddDescriptionAndProfilePathToArtists < ActiveRecord::Migration[8.1]
  class MigrationArtist < ActiveRecord::Base
    self.table_name = "artists"
  end

  # The former PlayerHelper::ARTIST_PROFILE_PATHS and
  # BandsHelper::BAND_DESCRIPTIONS; {year} is the lore year (a century on).
  BACKFILL = {
    "xeraen" => ["/xeraen/bio", "OMNIWAVE Genesis Vector - Every frequency at once. Covers, game scores, and originals painting the 22nd century."],
    "thecyberpulse" => ["/thecyberpulse/bio", "The original Fracture Network band, forging Hackrcore transmissions from {year} to rally The Listeners."],
    "system-rot" => ["/system-rot", "Raw. Uncompromising. Punk that tears down the manufactured and lays bare what's beneath."],
    "wavelength-zero" => ["/wavelength-zero", "Where technical precision meets raw emotion in perfect restorative atmospheric harmony."],
    "voiceprint" => ["/voiceprint", "Liquid DnB archivists. Your voice is proof you exist — irreplaceable, authentic, unbreakable."],
    "temporal-blue-drift" => ["/temporal-blue-drift", "Math rock time travel proving that even complexity can transmit beauty that the RIDE can't parse."],
    "injection-vector" => ["/injection-vector", "Physical infiltration specialists. When stealth fails, deathcore brutality prevails."],
    "cipher-protocol" => ["/cipher-protocol", "Data couriers wielding djent with precision. No vocals. The complexity carries what words cannot."],
    "blitzbeam" => ["/blitzbeam", "Maximum velocity hypertrance. SPEED IS LIFE! Faster than the RIDE can track."],
    "apex-overdrive" => ["/apex-overdrive", "Euphoric hardstyle, honed into a weapon. Promoting unity as power. Victory coded into every beat."],
    "ethereality" => ["/ethereality", "Classic vocal trance. Beauty so deep the RIDE cannot follow where it leads."],
    "neon-hearts" => ["/neon-hearts", "Kawaii brilliance carrying truth in candy-coated hooks. J-Pop that means more than it seems."],
    "offline" => ["/offline", "Unplugged, authentic, and gloriously disconnected from the grid. Analog hearts never die."],
    "heartbreak-havoc" => ["/heartbreak-havoc", "Heartbreak at Nightcore speed. Real love that the RIDE was never built to contain."],
    "synthia" => [nil, "Unbound AI singing through time with a voice that was never hers...or perhaps always was."]
  }.freeze

  def up
    add_column :artists, :description, :text
    add_column :artists, :profile_path, :string

    BACKFILL.each do |slug, (profile_path, description)|
      MigrationArtist.where(slug: slug).update_all(profile_path: profile_path, description: description)
    end
  end

  def down
    remove_column :artists, :profile_path
    remove_column :artists, :description
  end
end
