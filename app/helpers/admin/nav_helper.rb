module Admin
  # The /root nav bar's active-section marking (admin/shared/_nav,
  # admin_chrome.css; 2026-10-30). One top item lights per request —
  # SECTIONS is ordered, first match wins: Hackrs (grid_hackrs + its
  # grid_hackr_* sub-resources, the grid/hackrs/* POSTs) before the
  # grid_* family, the dashboard last and exact. Inside a dropdown the
  # entry whose path owns the request is barred too (admin_nav_link).
  module NavHelper
    # Patterns: "/root/x" = x itself or anything under it; "/root/x*" = a
    # raw prefix (a family of resources); "=/root" = exactly that path.
    SECTIONS = [
      [:hackrs, %w[/root/grid_hackr* /root/grid/hackrs*]],
      [:music, %w[/root/artists /root/releases /root/tracks /root/radio_stations /root/zone_playlists]],
      [:logs, %w[/root/hackr_logs]],
      [:codex, %w[/root/codex_entries]],
      [:handbook, %w[/root/handbook_sections /root/handbook_articles]],
      [:streams, %w[/root/hackr_streams]],
      [:pulsewire, %w[/root/pulse_wire]],
      [:emotes, %w[/root/emotes]],
      [:uplink, %w[/root/uplink]],
      [:grid, %w[/root/grid /root/grid_*]],
      [:meta, %w[/root/error_groups /root/data_audit_flags /root/analytics /root/overlays /root/world_event_feed /root/redirects /root/test_*]],
      [:dashboard, %w[=/root]]
    ].freeze

    def admin_nav_section
      path = request.path
      SECTIONS.each do |section, patterns|
        return section if patterns.any? { |pattern| admin_nav_match?(path, pattern) }
      end
      nil
    end

    def admin_nav_match?(path, pattern)
      if pattern.end_with?("*")
        path.start_with?(pattern.delete_suffix("*"))
      elsif pattern.start_with?("=")
        path == pattern.delete_prefix("=")
      else
        path == pattern || path.start_with?("#{pattern}/")
      end
    end

    # <li> for a top item: `is-active` when the request sits in its
    # section; dropdown items get the hover-menu classes.
    def admin_nav_item(section, dropdown: false, end_aligned: false, &block)
      classes = class_names(
        "admin-nav-dropdown" => dropdown,
        "admin-nav-dropdown--end" => end_aligned,
        "is-active" => admin_nav_section == section
      ).presence
      tag.li(class: classes, &block)
    end

    # A nav link: `is-active` + aria-current when the request path is the
    # link's path or under it (`match:` overrides the pattern — "=/root"
    # for the dashboard, "/root/grid_map_editor*" for the editor, whose
    # href carries a region id).
    def admin_nav_link(label, path, css: nil, match: path, **options)
      active = admin_nav_match?(request.path, match)
      link_to label, path, **options, class: class_names(css, "is-active" => active).presence, "aria-current": ("page" if active)
    end
  end
end
