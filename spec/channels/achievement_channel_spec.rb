require "rails_helper"

RSpec.describe AchievementChannel, type: :channel do
  let(:hackr) { create(:grid_hackr) }

  it "rejects anonymous connections" do
    stub_connection current_hackr: nil
    subscribe
    expect(subscription).to be_rejected
  end

  it "streams from the per-hackr stream when authenticated" do
    stub_connection current_hackr: hackr
    subscribe
    expect(subscription).to be_confirmed
    expect(subscription).to have_stream_from("achievement_channel_#{hackr.id}")
  end

  it "exposes the stream name via the class helper" do
    expect(described_class.stream_name_for(hackr)).to eq("achievement_channel_#{hackr.id}")
  end
end
