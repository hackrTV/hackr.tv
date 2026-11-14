# Plain-Ruby config for the Hotwire band profile pages (Phase 4) — the
# ERB counterpart of the migrated bandProfileConfig.tsx entries. Keyed by
# artist slug. Band colors/typography live entirely in band_profiles.css
# behind the css: modifier class; the section content lives in the
# per-band partials under app/views/band_profiles/.
class BandProfile
  # partial: is a literal (never derived from params) so the render call
  # in show.html.erb stays off Brakeman's dynamic-render-path radar.
  CONFIG = {
    "system-rot" => {name: "System Rot", css: "band-profile--system-rot", partial: "system_rot"},
    "voiceprint" => {name: "Voiceprint", css: "band-profile--voiceprint", partial: "voiceprint"},
    "injection-vector" => {name: "Injection Vector", css: "band-profile--injection-vector", partial: "injection_vector"},
    "cipher-protocol" => {name: "Cipher Protocol", css: "band-profile--cipher-protocol", partial: "cipher_protocol"},
    "blitzbeam" => {name: "BlitzBeam+", css: "band-profile--blitzbeam", partial: "blitzbeam"},
    "apex-overdrive" => {name: "Apex Overdrive", css: "band-profile--apex-overdrive", partial: "apex_overdrive"},
    "ethereality" => {name: "Ethereality", css: "band-profile--ethereality", partial: "ethereality"},
    "neon-hearts" => {name: "Neon Hearts (ネオンハーツ)", css: "band-profile--neon-hearts", partial: "neon_hearts"},
    "offline" => {name: "Offline", css: "band-profile--offline", partial: "offline"},
    "temporal-blue-drift" => {name: "Temporal Blue Drift", css: "band-profile--temporal-blue-drift", partial: "temporal_blue_drift"},
    "heartbreak-havoc" => {name: "heartbreak_havoc.sh", css: "band-profile--heartbreak-havoc", partial: "heartbreak_havoc"}
  }.freeze
end
