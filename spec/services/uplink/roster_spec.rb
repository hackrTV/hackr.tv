require "rails_helper"

RSpec.describe Uplink::Roster do
  let(:channel) { create(:chat_channel) }
  let(:other_channel) { create(:chat_channel) }
  let(:admin) { create(:grid_hackr, :admin) }
  let(:operator) { create(:grid_hackr, :operator) }
  let(:operative) { create(:grid_hackr) }

  def present!(hackr, ch = channel, at: Time.current)
    GridUplinkPresence.touch!(hackr, ch).update_column(:last_seen_at, at)
  end

  it "groups connected hackrs by role in ADMIN/OPERATOR/OPERATIVE order, omitting empty groups" do
    present!(operative)
    present!(admin)

    roster = described_class.for(channel)

    expect(roster.members.size).to eq(2)
    expect(roster.groups.keys).to eq(%w[admin operative])
    expect(roster.groups["admin"].map(&:label)).to eq([Uplink::Callsign.label(admin.id)])
    expect(roster.groups["operative"].first.token).to eq(Uplink::Callsign.token(operative.id))
  end

  it "never exposes aliases" do
    present!(operator)

    roster = described_class.for(channel)

    expect(roster.members.map(&:to_h).to_s).not_to include(operator.hackr_alias)
    expect(roster.members.first.label).to match(/\ASIG-/)
  end

  it "ignores other channels, stale presences, and service accounts" do
    present!(operative, other_channel)
    present!(admin, at: (Grid::EconomyConfig::PRESENCE_TTL + 1.minute).ago)
    bot = create(:grid_hackr, :admin, service_account: true)
    present!(bot)

    expect(described_class.for(channel)).to be_empty
  end

  it "synthesizes the viewer's own row without writing presence, and never duplicates it" do
    roster = described_class.for(channel, viewer: operative)

    expect(roster.members.map(&:token)).to eq([Uplink::Callsign.token(operative.id)])
    expect(GridUplinkPresence.count).to eq(0)

    present!(operative)
    expect(described_class.for(channel, viewer: operative).members.size).to eq(1)
    expect(described_class.for(channel, viewer: create(:grid_hackr, service_account: true)).members.size).to eq(1)
  end

  it "is empty without a channel" do
    expect(described_class.for(nil, viewer: operative)).to be_empty
    expect(described_class.for(nil).groups).to eq({})
  end
end
