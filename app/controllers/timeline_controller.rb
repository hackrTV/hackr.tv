# Server-rendered lore timeline (Hotwire migration Phase 1) — ports
# TimelinePage.tsx and friends. Data from TimelineData (YAML-backed).
class TimelineController < ApplicationController
  layout "hotwire"

  # Rendering order mirrors the SPA: Listeners → Trade (atmospheric) →
  # Gap (with PRISM anchors) → Efficiency (header only) → GovCorp & RIDE →
  # Fracture → Fracture Network.
  def show
    @eras = TimelineData.era_map
    @events_by_era = TimelineData.eras.to_h { |e| [e["key"], TimelineData.events_by_era(e["key"])] }
  end
end
