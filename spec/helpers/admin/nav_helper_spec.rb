require "rails_helper"

RSpec.describe Admin::NavHelper, type: :helper do
  def at(path)
    allow(helper.request).to receive(:path).and_return(path)
  end

  describe "#admin_nav_section" do
    {
      "/root" => :dashboard,
      "/root/artists" => :music,
      "/root/artists/xeraen" => :music,
      "/root/releases/new" => :music,
      "/root/tracks" => :music,
      "/root/radio_stations" => :music,
      "/root/zone_playlists/3" => :music,
      "/root/hackr_logs" => :logs,
      "/root/codex_entries/new" => :codex,
      "/root/handbook_sections" => :handbook,
      "/root/handbook_articles/7/edit" => :handbook,
      "/root/hackr_streams" => :streams,
      "/root/pulse_wire" => :pulsewire,
      "/root/pulse_wire/pulse_drops" => :pulsewire,
      "/root/emotes/wave/edit" => :emotes,
      "/root/uplink/channels" => :uplink,
      "/root/grid" => :grid,
      "/root/grid_zones/3/edit" => :grid,
      "/root/grid_map_editor/region/1" => :grid,
      "/root/grid_world_export" => :grid,
      "/root/grid_hackrs" => :hackrs,
      "/root/grid_hackrs/9" => :hackrs,
      "/root/grid_hackr_items" => :hackrs,
      "/root/grid_hackr_missions" => :hackrs,
      "/root/grid/hackrs/9/reset_totp" => :hackrs,
      "/root/error_groups" => :meta,
      "/root/data_audit_flags" => :meta,
      "/root/analytics" => :meta,
      "/root/overlays/alerts" => :meta,
      "/root/world_event_feed" => :meta,
      "/root/redirects/new" => :meta,
      "/root/test_guide/40_admin_access" => :meta,
      "/root/test_runs/2" => :meta
    }.each do |path, section|
      it "maps #{path} to #{section}" do
        at(path)
        expect(helper.admin_nav_section).to eq(section)
      end
    end

    it "lights nothing on an unknown admin path" do
      at("/root/something_else")
      expect(helper.admin_nav_section).to be_nil
    end

    it "does not light the dashboard on a path that merely starts with /root" do
      at("/rootkit")
      expect(helper.admin_nav_section).to be_nil
    end
  end

  describe "#admin_nav_match?" do
    it "matches a path exactly or under it, on a segment boundary" do
      expect(helper.admin_nav_match?("/root/codex_entries", "/root/codex_entries")).to be(true)
      expect(helper.admin_nav_match?("/root/codex_entries/3", "/root/codex_entries")).to be(true)
      expect(helper.admin_nav_match?("/root/codex_entries_archive", "/root/codex_entries")).to be(false)
    end

    it "matches a raw prefix family on *" do
      expect(helper.admin_nav_match?("/root/grid_hackr_items", "/root/grid_hackr*")).to be(true)
      expect(helper.admin_nav_match?("/root/grid_zones", "/root/grid_hackr*")).to be(false)
    end

    it "matches exactly on =" do
      expect(helper.admin_nav_match?("/root", "=/root")).to be(true)
      expect(helper.admin_nav_match?("/root/artists", "=/root")).to be(false)
    end
  end

  describe "#admin_nav_link" do
    it "marks the link whose path owns the request" do
      at("/root/artists/xeraen")
      html = helper.admin_nav_link("Artists", "/root/artists", css: "cyan-168-text")
      expect(html).to include('class="cyan-168-text is-active"')
      expect(html).to include('aria-current="page"')
    end

    it "leaves other links plain, without an empty class or aria-current" do
      at("/root/tracks")
      html = helper.admin_nav_link("Artists", "/root/artists", css: "cyan-168-text")
      expect(html).to eq('<a class="cyan-168-text" href="/root/artists">Artists</a>')
    end

    it "takes an explicit match pattern" do
      at("/root/grid_map_editor/region/4")
      html = helper.admin_nav_link("Map Editor", "/root/grid_map_editor/region/1", match: "/root/grid_map_editor*")
      expect(html).to include('aria-current="page"')
    end
  end

  describe "#admin_nav_item" do
    it "renders the li with the dropdown classes and is-active for the current section" do
      at("/root/grid_zones")
      html = helper.admin_nav_item(:grid, dropdown: true) { "Grid" }
      expect(html).to eq('<li class="admin-nav-dropdown is-active">Grid</li>')
    end

    it "renders a bare li elsewhere" do
      at("/root/grid_zones")
      expect(helper.admin_nav_item(:music) { "Music" }).to eq("<li>Music</li>")
    end
  end
end
