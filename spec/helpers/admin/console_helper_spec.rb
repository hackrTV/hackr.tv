require "rails_helper"

# Admin::ConsoleHelper — the /root console's shared screen helpers:
# the section destination tables, the prompt hint, [NN], filter rows,
# the pager, badges and the hidden DELETE forms
# (console-ui-for-all-admin Phase 0, 2026-10-30).
RSpec.describe Admin::ConsoleHelper, type: :helper do
  # Admin::DevToolsGate#dev_tools_enabled? is a controller helper_method.
  def dev_tools(on)
    helper.define_singleton_method(:dev_tools_enabled?) { on }
  end

  before { dev_tools(false) }

  describe "ROOT_SECTIONS" do
    it "reaches every path the nav's sections own" do
      dev_tools(true)
      hrefs = described_class::ROOT_SECTIONS.keys.flat_map { |section| helper.root_section_rows(section).map { |_, href, *| href } }
      Admin::NavHelper::SECTIONS.each do |section, patterns|
        patterns.each do |pattern|
          next if pattern == "=/root" || pattern == "/root/grid/hackrs*" # the dashboard; POST-only hackr actions
          prefix = pattern.delete_suffix("*")
          expect(hrefs.any? { |href| href.start_with?(prefix) }).to be(true), "no destination under #{pattern} (#{section})"
        end
      end
    end

    it "lists the dev-tool screens only while the gate is on" do
      expect(helper.root_section_rows(:hackrs).map(&:first)).to eq(%w[HACKRS])
      dev_tools(true)
      rows = helper.root_section_rows(:hackrs)
      expect(rows.map(&:first)).to eq(%w[HACKRS SANDBOX NPC PAC])
      expect(rows.map(&:second)).to eq(%w[/root/grid_hackrs /root/grid_breach_sandbox/new /root/grid_npc_dialogue_tester/new /root/grid_pac_escape_tester/new])
    end

    it "routes the map editor to the first region, and drops the row while there is none" do
      expect(helper.root_section_rows(:world).map(&:first)).not_to include("MAP")
      region = create(:grid_region)
      expect(helper.root_section_rows(:world).find { |tag_name, *| tag_name == "MAP" }[1]).to eq("/root/grid_map_editor/region/#{region.id}")
    end
  end

  describe "#root_destinations" do
    it "ends on ROOT and drops the screen's own tag" do
      rows = helper.root_destinations(:music, except: "ARTISTS")
      expect(rows.map(&:first)).to eq(%w[RELEASES TRACKS RADIO ROOT])
      expect(rows.last).to eq(["ROOT", "/root", "Dashboard", "Back to the /root overview"])
      expect(rows.first).to eq(["RELEASES", "/root/releases", "Releases", "Albums, EPs and singles across the catalog"])
    end
  end

  describe "#root_prompt_hint" do
    it "names the numbers (a range past eight), the extra commands and the section's tags" do
      hint = helper.root_prompt_hint(:music, except: "TRACKS", numbers: (1..9).map { |n| format("%02d", n) }, noun: "a track number", extra: ["new"])
      expect(hint).to include("type a track number ")
      expect(hint).to include('<span class="console-dim">(01–09)</span>')
      expect(hint).to include('<span class="console-dim">(new artists releases radio root)</span>')
      expect(hint).to end_with(" · enter · ? help")
    end

    it "lists the numbers when there are eight or fewer, and only the tags without any" do
      expect(helper.root_prompt_hint(:meta, numbers: %w[01 02])).to include("(01 02)")
      expect(helper.root_prompt_hint(:meta)).to start_with("type a tag ")
      expect(helper.root_prompt_hint(:meta)).to include("(errors flags analytics guide runs root)")
    end
  end

  describe "#root_num" do
    it "pads to two digits, or to the ledger's width" do
      expect(helper.root_num(0)).to eq("01")
      expect(helper.root_num(3, total: 7)).to eq("04")
      expect(helper.root_num(3, total: 5902)).to eq("0004")
    end
  end

  describe "#root_field" do
    it "wraps the block in a status row keyed by a label for the input's id" do
      html = helper.root_field("FILTER", id: "q") { helper.tag.input(id: "q") }
      expect(html).to eq('<div class="console-status-row rc-field"><label class="console-key" for="q">FILTER</label><span class="console-val"><input id="q"></span></div>')
    end

    it "keys with a span when there is no id" do
      expect(helper.root_field("RANGE") { "x" }).to start_with('<div class="console-status-row rc-field"><span class="console-key">RANGE</span>')
    end
  end

  describe "#root_pager" do
    before do
      allow(helper.request).to receive_messages(path: "/root/grid_transactions", query_parameters: {"kind" => "mine", "offset" => "50"})
    end

    it "renders nothing when the ledger fits" do
      expect(helper.root_pager(0, 50, 50)).to be_nil
    end

    it "links PREV and NEXT keeping the other query parameters" do
      html = Capybara.string(helper.root_pager(50, 50, 120))
      expect(html).to have_css("div.rc-pager > a.rc-btn[href='/root/grid_transactions?kind=mine&offset=0']", text: "[<] PREV")
      expect(html).to have_css("span.rc-count", text: "51–100 of 120")
      expect(html).to have_css("a.rc-btn[href='/root/grid_transactions?kind=mine&offset=100']", text: "[>] NEXT")
    end

    it "disables the edge buttons" do
      first = Capybara.string(helper.root_pager(0, 50, 60))
      expect(first).to have_css("span.rc-btn[disabled]", text: "[<] PREV")
      expect(first).to have_css("a.rc-btn[href='/root/grid_transactions?kind=mine&offset=50']", text: "[>] NEXT")
      last = Capybara.string(helper.root_pager(50, 50, 60))
      expect(last).to have_css("span.rc-count", text: "51–60 of 60")
      expect(last).to have_css("span.rc-btn[disabled]", text: "[>] NEXT")
    end
  end

  describe "#root_badge" do
    it "renders a toned bar badge, the admin's cyan by default" do
      expect(helper.root_badge("DEV TOOLS ON", :warn)).to eq('<span class="console-bar-badge rc-badge--warn">DEV TOOLS ON</span>')
      expect(helper.root_badge("LIVE")).to eq('<span class="console-bar-badge rc-badge--hot">LIVE</span>')
    end
  end

  describe "#root_delete_form" do
    it "renders a hidden DELETE form carrying the confirm" do
      html = Capybara.string(helper.root_delete_form("delete-x", "/root/artists/x", confirm: "Delete?"))
      expect(html).to have_css("form#delete-x[action='/root/artists/x'][method='post'][data-confirm='Delete?']", visible: :all)
      expect(html).to have_css("form#delete-x input[name='_method'][value='delete']", visible: :all)
    end
  end
end
