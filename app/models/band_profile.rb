# Plain-Ruby config for the Hotwire band profile pages (Phase 4) — the
# ERB counterpart of the migrated bandProfileConfig.tsx entries. Keyed by
# artist slug. Band colors/typography live entirely in band_profiles.css
# behind the css: modifier class; the section content lives in the
# per-band partials under app/views/band_profiles/.
class BandProfile
  # partial: is a literal (never derived from params) so the render call
  # in show.html.erb stays off Brakeman's dynamic-render-path radar.
  CONFIG = {
    "system-rot" => {name: "System Rot", filter_name: "system rot", css: "band-profile--system-rot", partial: "system_rot"},
    "voiceprint" => {name: "Voiceprint", filter_name: "voiceprint", css: "band-profile--voiceprint", partial: "voiceprint"},
    "injection-vector" => {name: "Injection Vector", filter_name: "injection vector", css: "band-profile--injection-vector", partial: "injection_vector"},
    "cipher-protocol" => {name: "Cipher Protocol", filter_name: "cipher protocol", css: "band-profile--cipher-protocol", partial: "cipher_protocol"},
    "blitzbeam" => {name: "BlitzBeam+", filter_name: "blitzbeam", css: "band-profile--blitzbeam", partial: "blitzbeam"},
    "apex-overdrive" => {name: "Apex Overdrive", filter_name: "apex overdrive", css: "band-profile--apex-overdrive", partial: "apex_overdrive"},
    "ethereality" => {name: "Ethereality", filter_name: "ethereality", css: "band-profile--ethereality", partial: "ethereality"},
    "neon-hearts" => {name: "Neon Hearts (ネオンハーツ)", filter_name: "neon hearts", css: "band-profile--neon-hearts", partial: "neon_hearts"},
    "offline" => {name: "Offline", filter_name: "offline", css: "band-profile--offline", partial: "offline"},
    "temporal-blue-drift" => {name: "Temporal Blue Drift", filter_name: "temporal blue drift", css: "band-profile--temporal-blue-drift", partial: "temporal_blue_drift"},
    "heartbreak-havoc" => {name: "heartbreak_havoc.sh", filter_name: "heartbreak havoc", css: "band-profile--heartbreak-havoc", partial: "heartbreak_havoc"}
  }.freeze
end
