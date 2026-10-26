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

  describe ".counts (the sidebar rows)" do
    it "counts valid, non-service presence rows per channel for every channel given, the viewer added on the channel they view until their row lands" do
      present!(operative)
      present!(admin)
      present!(operator, other_channel)
      present!(create(:grid_hackr, service_account: true))
      present!(create(:grid_hackr), at: (Grid::EconomyConfig::PRESENCE_TTL + 1.minute).ago)
      third = create(:chat_channel)

      expect(described_class.counts([channel, other_channel, third])).to eq(channel.id => 2, other_channel.id => 1, third.id => 0)
      expect(described_class.counts([channel, third], viewer: operator, viewing: third)).to eq(channel.id => 2, third.id => 1)
      expect(described_class.counts([channel], viewer: operative, viewing: channel)).to eq(channel.id => 2) # already there: not twice
      expect(described_class.counts([channel], viewer: create(:grid_hackr, service_account: true), viewing: channel)).to eq(channel.id => 2)
      expect(described_class.counts([channel], viewer: operator, viewing: other_channel)).to eq(channel.id => 2) # viewing a channel not listed
      expect(described_class.counts([], viewer: operator, viewing: channel)).to eq({})
      expect(GridUplinkPresence.where(grid_hackr: operator, chat_channel: third).count).to eq(0) # no write on a read
    end
  end
end
