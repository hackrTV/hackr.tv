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
    "blitzbeam" => {name: "BlitzBeam+", filter_name: "blitzbeam", css: "band-profile--blitzbeam", partial: "blitzbeam"},
    "ethereality" => {name: "Ethereality", filter_name: "ethereality", css: "band-profile--ethereality", partial: "ethereality"},
    "offline" => {name: "Offline", filter_name: "offline", css: "band-profile--offline", partial: "offline"}
  }.freeze
end
