require "rails_helper"

RSpec.describe LiveWatch::SweepJob, type: :job do
  it "closes stale open sessions" do
    hackr = create(:grid_hackr)
    stale = HackrWatchSession.create!(
      grid_hackr: hackr,
      connected_at: 10.minutes.ago,
      last_heartbeat_at: 10.minutes.ago,
      accumulated_seconds: 60
    )

    described_class.perform_now

    expect(stale.reload.disconnected_at).to be_present
  end
end
