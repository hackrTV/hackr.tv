# frozen_string_literal: true

module Grid
  class TransitRenderer
    class << self
      # === Local Transit ===

      def render_board(journey, route, stop)
        type = route.grid_transit_type
        lines = []
        lines << ""
        lines << separator
        lines << "<span style='color: #22d3ee; font-weight: bold;'>#{icon(type)} BOARDING: #{h(route.name)}</span>"
        lines << separator
        if journey.local_private?
          dest = journey.destination_room
          lines << "<span style='color: #9ca3af;'>Destination: #{h(dest&.name || "unknown")}</span>"
          lines << "<span style='color: #9ca3af;'>Fare: #{journey.fare_paid} CRED</span>"
          lines << ""
          lines << "<span style='color: #6b7280;'>Type <span style='color: #22d3ee;'>wait</span> to travel. <span style='color: #22d3ee;'>abandon</span> to cancel.</span>"
        else
          lines << "<span style='color: #9ca3af;'>Boarded at: #{h(stop.display_name)}</span>"
          lines << "<span style='color: #9ca3af;'>Fare: #{journey.fare_paid} CRED</span>"
          lines << ""
          lines << render_route_stops(route, stop)
          lines << ""
          lines << "<span style='color: #6b7280;'>Type <span style='color: #22d3ee;'>wait</span> to ride to next stop. <span style='color: #22d3ee;'>disembark</span> to exit.</span>"
        end
        lines.join("\n")
      end

      def render_wait(journey, stop, arrived, route)
        type = route.grid_transit_type
        lines = []
        lines << ""
        if arrived
          lines << "<span style='color: #34d399; font-weight: bold;'>#{icon(type)} ARRIVED: #{h(stop.display_name)}</span>"
          lines << "<span style='color: #9ca3af;'>You have reached your destination.</span>"
        else
          lines << "<span style='color: #9ca3af;'>#{icon(type)} Now at:</span> <span style='color: #22d3ee; font-weight: bold;'>#{h(stop.display_name)}</span>"
          remaining = remaining_stops(route, stop)
          lines << "<span style='color: #6b7280;'>#{remaining} stop(s) remaining.</span>" if remaining > 0
          lines << ""
          lines << "<span style='color: #6b7280;'>Type <span style='color: #22d3ee;'>wait</span> to continue. <span style='color: #22d3ee;'>disembark</span> to exit here.</span>"
        end
        lines.join("\n")
      end

      def render_end_of_line(journey, stop)
        lines = []
        lines << ""
        lines << "<span style='color: #fbbf24; font-weight: bold;'>END OF LINE</span>"
        lines << "<span style='color: #9ca3af;'>Final stop: #{h(stop.display_name)}. You have been disembarked.</span>"
        lines.join("\n")
      end

      def render_disembark(journey, room)
        lines = []
        lines << ""
        lines << "<span style='color: #34d399;'>You disembark at #{h(room.name)}.</span>"
        lines.join("\n")
      end

      def render_abandon(journey)
        lines = []
        lines << ""
        lines << "<span style='color: #fbbf24;'>Transit abandoned. Returned to #{h(journey.origin_room&.name || "origin")}.</span>"
        lines.join("\n")
      end

      def render_local_status(journey)
        route = journey.grid_transit_route
        type = route.grid_transit_type
        stop = journey.current_stop
        lines = []
        lines << ""
        lines << separator
        lines << "<span style='color: #22d3ee; font-weight: bold;'>#{icon(type)} IN TRANSIT: #{h(route.name)}</span>"
        lines << separator
        lines << "<span style='color: #9ca3af;'>Current stop: #{h(stop&.display_name || "unknown")}</span>"
        if journey.local_private?
          lines << "<span style='color: #9ca3af;'>Destination: #{h(journey.destination_room&.name || "unknown")}</span>"
        else
          remaining = remaining_stops(route, stop)
          lines << "<span style='color: #6b7280;'>#{remaining} stop(s) to end of line.</span>"
        end
        lines << "<span style='color: #9ca3af;'>Fare paid: #{journey.fare_paid} CRED</span>"
        lines.join("\n")
      end

      # === Private Transit (route-free) ===

      def render_private_board(journey, transit_type, destination_room)
        lines = []
        lines << ""
        lines << separator
        lines << "<span style='color: #fbbf24; font-weight: bold;'>[#{h(transit_type.icon_key || "PRIVATE")}] #{h(transit_type.name).upcase}</span>"
        lines << separator
        lines << "<span style='color: #9ca3af;'>Destination: <span style='color: #22d3ee; font-weight: bold;'>#{h(destination_room.name)}</span> (#{h(destination_room.grid_zone.name)})</span>"
        lines << "<span style='color: #9ca3af;'>Fare: #{journey.fare_paid} CRED</span>"
        lines << ""
        lines << "<span style='color: #6b7280;'>Type <span style='color: #22d3ee;'>wait</span> to travel. <span style='color: #22d3ee;'>abandon</span> to cancel.</span>"
        lines.join("\n")
      end

      def render_private_arrival(journey, room)
        lines = []
        lines << ""
        type_slug = journey.meta&.dig("transit_type_slug")
        type = type_slug ? GridTransitType.find_by(slug: type_slug) : nil
        icon = type&.icon_key || "PRIVATE"
        lines << "<span style='color: #34d399; font-weight: bold;'>[#{h(icon)}] ARRIVED: #{h(room.name)}</span>"
        lines << "<span style='color: #9ca3af;'>#{h(room.grid_zone.name)}</span>"
        lines.join("\n")
      end

      def render_private_types(types, destinations, room)
        lines = []
        lines << "<span style='color: #fbbf24; font-weight: bold;'>[ PRIVATE TRANSIT ]</span>"
        types.each do |t|
          lines << "  <span style='color: #fbbf24;'>[#{h(t.icon_key || "PRIVATE")}]</span> <span style='color: #d0d0d0;'>#{h(t.name)}</span> <span style='color: #6b7280;'>— #{t.base_fare} CRED</span>"
        end
        lines << "<span style='color: #6b7280;'>  Destinations:</span>"
        destinations.each do |d|
          lines << "    <span style='color: #9ca3af;'>#{h(d.name)}</span> <span style='color: #6b7280;'>(#{h(d.grid_zone.name)})</span>"
        end
        type_example = types.first
        dest_example = destinations.first
        if type_example && dest_example
          lines << "<span style='color: #6b7280;'>  Use: <span style='color: #22d3ee;'>hail #{h(type_example.slug)} #{h(dest_example.name.downcase)}</span></span>"
        end
        lines.join("\n")
      end

      # === Slipstream ===

      def render_slipstream_board(journey, route, first_leg)
        lines = []
        lines << ""
        lines << separator
        lines << "<span style='color: #a78bfa; font-weight: bold;'>[SLIP] SLIPSTREAM INITIATED</span>"
        lines << separator
        lines << "<span style='color: #9ca3af;'>Route: #{h(route.name)}</span>"
        lines << "<span style='color: #9ca3af;'>Origin: #{h(route.origin_region.name)} → Destination: #{h(route.destination_region.name)}</span>"
        lines << "<span style='color: #9ca3af;'>Legs: #{route.leg_count}</span>"
        lines << ""
        lines << render_leg_prompt(first_leg, 1, route.leg_count)
        lines.join("\n")
      end

      def render_fork_chosen(journey, leg, option)
        lines = []
        lines << ""
        lines << "<span style='color: #a78bfa;'>Path chosen: <span style='font-weight: bold;'>#{h(option["label"])}</span></span>"
        lines << "<span style='color: #6b7280;'>#{h(option["description"])}</span>"
        lines << ""
        lines << "<span style='color: #6b7280;'>Type <span style='color: #a78bfa;'>advance</span> to traverse this leg.</span>"
        lines.join("\n")
      end

      def render_leg_advanced(journey, next_leg)
        route = journey.grid_slipstream_route
        lines = []
        lines << ""
        lines << "<span style='color: #34d399;'>Leg #{journey.legs_completed} cleared. No detection.</span>"
        lines << ""
        lines << render_leg_prompt(next_leg, journey.legs_completed + 1, route.leg_count)
        lines.join("\n")
      end

      def render_slipstream_breach(journey, leg)
        lines = []
        lines << ""
        lines << "<span style='color: #ef4444; font-weight: bold;'>\u26a0 SLIPSTREAM DETECTION — BREACH TRIGGERED</span>"
        lines << "<span style='color: #f87171;'>GovCorp surveillance has flagged anomalous traffic on this corridor.</span>"
        lines << "<span style='color: #f87171;'>Resolve the BREACH to continue transit.</span>"
        lines.join("\n")
      end

      def render_slipstream_penalty(journey, leg)
        route = journey.grid_slipstream_route
        lines = []
        lines << ""
        lines << "<span style='color: #ef4444; font-weight: bold;'>\u26a0 SLIPSTREAM DETECTION — SCAN INTERCEPTED</span>"
        lines << "<span style='color: #f87171;'>GovCorp surveillance flagged anomalous traffic. Without a functional DECK, you absorb the hit raw.</span>"
        lines << "<span style='color: #f87171;'>ENERGY -20 | PSYCHE -20 | Heat increased.</span>"
        lines << ""
        lines << "<span style='color: #fbbf24;'>Must replay current leg. Equip a DECK to survive future scans.</span>"
        lines << ""
        lines << render_leg_prompt(leg, journey.legs_completed + 1, route.leg_count)
        lines.join("\n")
      end

      def render_slipstream_arrival(journey, route)
        lines = []
        lines << ""
        lines << separator
        lines << "<span style='color: #34d399; font-weight: bold;'>[SLIP] SLIPSTREAM TRANSIT COMPLETE</span>"
        lines << separator
        lines << "<span style='color: #9ca3af;'>Arrived: #{h(route.destination_region.name)}</span>"
        lines << "<span style='color: #9ca3af;'>Legs traversed: #{journey.legs_completed}</span>"
        heat = journey.grid_hackr.slipstream_heat
        lines << "<span style='color: #{heat_color(heat)};'>Corridor heat: #{heat}/100</span>"
        lines.join("\n")
      end

      def render_slipstream_abandon(journey)
        lines = []
        lines << ""
        lines << "<span style='color: #fbbf24;'>[SLIP] Slipstream transit abandoned. Returned to origin.</span>"
        lines.join("\n")
      end

      def render_slipstream_ejection(journey, severity)
        lines = []
        lines << ""
        lines << "<span style='color: #ef4444; font-weight: bold;'>[SLIP] EJECTED FROM SLIPSTREAM</span>"
        case severity
        when :severe
          lines << "<span style='color: #f87171;'>Heavy detection. ENERGY -30 | PSYCHE -30 | HEALTH -15</span>"
          lines << "<span style='color: #f87171;'>Returned to origin region. Corridor locked out for 5 minutes.</span>"
        when :fatal
          lines << "<span style='color: #ef4444;'>Critical detection — corridor burned.</span>"
          lines << "<span style='color: #f87171;'>ENERGY -40 | PSYCHE -40 | HEALTH -30</span>"
          lines << "<span style='color: #f87171;'>Returned to origin region. Corridor locked out for 10 minutes.</span>"
        end
        lines.join("\n")
      end

      def render_breach_survived(journey)
        lines = []
        lines << ""
        lines << "<span style='color: #34d399;'>[SLIP] BREACH resolved. Slipstream transit resumed.</span>"
        lines << "<span style='color: #fbbf24;'>Corridor heat increased from detection event.</span>"
        lines << ""
        leg = journey.current_leg
        if leg
          route = journey.grid_slipstream_route
          lines << render_leg_prompt(leg, journey.legs_completed + 1, route.leg_count)
        end
        lines.join("\n")
      end

      def render_breach_failed_replay(journey)
        lines = []
        lines << ""
        lines << "<span style='color: #fbbf24;'>[SLIP] BREACH failed. Must replay current leg.</span>"
        lines << "<span style='color: #f87171;'>Corridor heat rising.</span>"
        lines << ""
        leg = journey.current_leg
        if leg
          route = journey.grid_slipstream_route
          lines << render_leg_prompt(leg, journey.legs_completed + 1, route.leg_count)
        end
        lines.join("\n")
      end

      def render_breach_jackout_resume(journey)
        lines = []
        lines << ""
        lines << "<span style='color: #fbbf24;'>[SLIP] Jacked out of BREACH. Transit continues — heat increased.</span>"
        lines << ""
        leg = journey.current_leg
        if leg
          route = journey.grid_slipstream_route
          lines << render_leg_prompt(leg, journey.legs_completed + 1, route.leg_count)
        end
        lines.join("\n")
      end

      def render_slipstream_status(journey, hackr)
        route = journey.grid_slipstream_route
        leg = journey.current_leg
        heat = hackr.slipstream_heat
        lines = []
        lines << ""
        lines << separator
        lines << "<span style='color: #a78bfa; font-weight: bold;'>[SLIP] SLIPSTREAM STATUS</span>"
        lines << separator
        lines << "<span style='color: #9ca3af;'>Route: #{h(route.name)}</span>"
        lines << "<span style='color: #9ca3af;'>#{h(route.origin_region.name)} → #{h(route.destination_region.name)}</span>"
        lines << "<span style='color: #9ca3af;'>Progress: #{journey.legs_completed}/#{route.leg_count} legs</span>"
        lines << "<span style='color: #9ca3af;'>Current: #{h(leg&.name || "unknown")}</span>"
        lines << "<span style='color: #{heat_color(heat)};'>Corridor heat: #{heat}/100 (#{hackr.slipstream_heat_tier})</span>"
        if journey.awaiting_fork?
          lines << ""
          lines << "<span style='color: #fbbf24;'>FORK DECISION PENDING — choose a path.</span>"
        elsif journey.breach_mid_journey?
          lines << ""
          lines << "<span style='color: #ef4444;'>BREACH IN PROGRESS — resolve before continuing.</span>"
        end
        lines.join("\n")
      end

      # === Shared Helpers ===

      def render_available_routes(routes, hackr)
        return "<span style='color: #9ca3af;'>No transit available from this location.</span>" if routes.empty?

        lines = []
        lines << ""
        lines << separator
        lines << "<span style='color: #22d3ee; font-weight: bold;'>TRANSIT ROUTES</span>"
        lines << separator

        routes.group_by { |r| r.grid_transit_type }.each do |type, type_routes|
          lines << "<span style='color: #a78bfa;'>#{icon(type)} #{h(type.name)} (#{type.category})</span>"
          type_routes.each do |route|
            fare_text = (type.base_fare > 0) ? " — #{type.base_fare} CRED" : ""
            stop_count = route.grid_transit_stops.size
            lines << "  <span style='color: #22d3ee;'>board #{h(route.slug)}</span>  <span style='color: #9ca3af;'>#{h(route.name)} (#{stop_count} stops#{fare_text})</span>"
          end
          lines << ""
        end
        lines.join("\n")
      end

      def render_slipstream_routes(routes, hackr)
        return "<span style='color: #9ca3af;'>No Slipstream routes available from this region.</span>" if routes.empty?

        heat = hackr.slipstream_heat
        lines = []
        lines << ""
        lines << separator
        lines << "<span style='color: #a78bfa; font-weight: bold;'>[SLIP] SLIPSTREAM CORRIDORS</span>"
        lines << separator
        lines << "<span style='color: #{heat_color(heat)};'>Current heat: #{heat}/100 (#{hackr.slipstream_heat_tier})</span>"
        lines << ""

        routes.each do |route|
          legs = route.leg_count
          room_name = route.origin_room&.name || "unknown"
          zone_name = route.origin_room&.grid_zone&.name || "unknown"
          lockout_until = hackr.stat("slip_lockout_#{route.slug}").to_i
          locked = lockout_until > 0 && Time.current.to_i < lockout_until
          if locked
            remaining = ((lockout_until - Time.current.to_i) / 60.0).ceil
            lines << "  <span style='color: #6b7280;'>slipstream #{h(route.slug)}</span>  <span style='color: #f87171;'>→ #{h(route.destination_region.name)} [LOCKED OUT — #{remaining}m remaining]</span>"
          else
            lines << "  <span style='color: #a78bfa;'>slipstream #{h(route.slug)}</span>  <span style='color: #9ca3af;'>→ #{h(route.destination_region.name)} (#{legs} legs, CL#{route.min_clearance}+)</span>"
          end
          lines << "    <span style='color: #6b7280;'>Board at: #{h(room_name)} (#{h(zone_name)})</span>"
        end
        lines << ""
        lines << "<span style='color: #6b7280;'>Use <span style='color: #a78bfa;'>slipstream &lt;slug&gt;</span> at the access point to initiate transit.</span>"
        lines.join("\n")
      end

      def render_leg_prompt(leg, leg_number, total_legs)
        lines = []
        lines << "<span style='color: #a78bfa; font-weight: bold;'>LEG #{leg_number}/#{total_legs}: #{h(leg.name)}</span>"
        lines << "<span style='color: #6b7280;'>#{h(leg.description)}</span>" if leg.description.present?
        lines << ""
        if leg.has_forks?
          lines << "<span style='color: #fbbf24;'>Choose your path:</span>"
          leg.fork_options.each do |opt|
            risk = opt["risk_modifier"].to_i
            risk_label = if risk < 0
              "<span style='color: #34d399;'>low risk</span>"
            elsif risk > 10
              "<span style='color: #ef4444;'>high risk</span>"
            else
              "<span style='color: #fbbf24;'>moderate risk</span>"
            end
            lines << "  <span style='color: #a78bfa;'>choose #{h(opt["key"])}</span>  <span style='color: #9ca3af;'>#{h(opt["label"])} — #{h(opt["description"])} (#{risk_label})</span>"
          end
        else
          lines << "<span style='color: #6b7280;'>Type <span style='color: #a78bfa;'>advance</span> to traverse this leg.</span>"
        end
        lines.join("\n")
      end

      private

      def h(text) = ERB::Util.html_escape(text.to_s)

      def separator
        "<span style='color: #a78bfa;'>════════════════════════════════════════</span>"
      end

      def icon(type)
        type.icon_key.present? ? "[#{type.icon_key.upcase}]" : "[TRANSIT]"
      end

      def render_route_stops(route, current_stop)
        stops = route.grid_transit_stops.order(:position).to_a
        stops.map { |s|
          marker = (s.id == current_stop.id) ? "►" : "·"
          color = (s.id == current_stop.id) ? "#22d3ee" : "#6b7280"
          "<span style='color: #{color};'>  #{marker} #{h(s.display_name)}</span>"
        }.join("\n")
      end

      def remaining_stops(route, current_stop)
        stops = route.grid_transit_stops.order(:position).to_a
        idx = stops.index { |s| s.id == current_stop.id }
        return 0 unless idx
        stops.size - idx - 1
      end

      def heat_color(heat)
        case heat
        when 0..9 then "#34d399"
        when 10..40 then "#fbbf24"
        when 41..70 then "#f97316"
        else "#ef4444"
        end
      end
    end
  end
end
