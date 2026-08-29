module BandsHelper
  # Ported verbatim from BandsPage.tsx getBandDescription. thecyberpulse is
  # built in band_description — it interpolates the future year.
  BAND_DESCRIPTIONS = {
    "xeraen" => "OMNIWAVE Genesis Vector - Every frequency at once. Covers, game scores, and originals painting the 22nd century.",
    "injection-vector" => "Physical infiltration specialists. When stealth fails, deathcore brutality prevails.",
    "wavelength-zero" => "Where technical precision meets raw emotion in perfect restorative atmospheric harmony.",
    "cipher-protocol" => "Data couriers wielding djent with precision. No vocals. The complexity carries what words cannot.",
    "system-rot" => "Raw. Uncompromising. Punk that tears down the manufactured and lays bare what's beneath.",
    "temporal-blue-drift" => "Math rock time travel proving that even complexity can transmit beauty that the RIDE can't parse.",
    "offline" => "Unplugged, authentic, and gloriously disconnected from the grid. Analog hearts never die.",
    "apex-overdrive" => "Euphoric hardstyle, honed into a weapon. Promoting unity as power. Victory coded into every beat.",
    "voiceprint" => "Liquid DnB archivists. Your voice is proof you exist — irreplaceable, authentic, unbreakable.",
    "neon-hearts" => "Kawaii brilliance carrying truth in candy-coated hooks. J-Pop that means more than it seems.",
    "ethereality" => "Classic vocal trance. Beauty so deep the RIDE cannot follow where it leads.",
    "blitzbeam" => "Maximum velocity hypertrance. SPEED IS LIFE! Faster than the RIDE can track.",
    "heartbreak-havoc" => "Heartbreak at Nightcore speed. Real love that the RIDE was never built to contain.",
    "synthia" => "Unbound AI singing through time with a voice that was never hers...or perhaps always was."
  }.freeze

  def band_description(slug)
    if slug == "thecyberpulse"
      "The original Fracture Network band, forging Hackrcore transmissions from #{Date.current.year + 100} to rally The Listeners."
    else
      BAND_DESCRIPTIONS[slug.to_s] || "Broadcasting truth through sound."
    end
  end
end
