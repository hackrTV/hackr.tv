# == Schema Information
#
# Table name: overlay_alerts
# Database name: primary
#
#  id           :integer          not null, primary key
#  alert_type   :string           not null
#  data         :json
#  displayed    :boolean          default(FALSE)
#  displayed_at :datetime
#  expires_at   :datetime
#  message      :text
#  title        :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#
# Indexes
#
#  index_overlay_alerts_on_alert_type  (alert_type)
#  index_overlay_alerts_on_displayed   (displayed)
#  index_overlay_alerts_on_expires_at  (expires_at)
#
require "rails_helper"

RSpec.describe OverlayAlert, type: :model do
  describe "validations" do
    it { should validate_presence_of(:alert_type) }
    it { should validate_inclusion_of(:alert_type).in_array(OverlayAlert::ALERT_TYPES) }
  end

  describe "scopes" do
    describe ".pending" do
      it "returns undisplayed alerts" do
        pending_alert = create(:overlay_alert, displayed: false)
        displayed_alert = create(:overlay_alert, :displayed)

        expect(OverlayAlert.pending).to include(pending_alert)
        expect(OverlayAlert.pending).not_to include(displayed_alert)
      end

      it "excludes expired alerts" do
        valid_alert = create(:overlay_alert, displayed: false, expires_at: 1.hour.from_now)
        expired_alert = create(:overlay_alert, :expired, displayed: false)

        expect(OverlayAlert.pending).to include(valid_alert)
        expect(OverlayAlert.pending).not_to include(expired_alert)
      end

      it "includes alerts without expiration" do
        no_expiry_alert = create(:overlay_alert, displayed: false, expires_at: nil)
        expect(OverlayAlert.pending).to include(no_expiry_alert)
      end
    end

    describe ".displayed" do
      it "returns displayed alerts" do
        displayed = create(:overlay_alert, :displayed)
        pending = create(:overlay_alert, displayed: false)

        expect(OverlayAlert.displayed).to include(displayed)
        expect(OverlayAlert.displayed).not_to include(pending)
      end
    end

    describe ".recent" do
      it "orders by created_at descending" do
        create(:overlay_alert, created_at: 2.days.ago)
        new_alert = create(:overlay_alert, created_at: 1.hour.ago)

        expect(OverlayAlert.recent.first).to eq(new_alert)
      end
    end

    describe ".by_type" do
      it "filters by alert type" do
        subscriber = create(:overlay_alert, :subscriber)
        donation = create(:overlay_alert, :donation)

        expect(OverlayAlert.by_type("subscriber")).to include(subscriber)
        expect(OverlayAlert.by_type("subscriber")).not_to include(donation)
      end
    end
  end

  describe ".queue!" do
    before do
      allow(ActionCable.server).to receive(:broadcast)
    end

    it "creates a new alert" do
      expect {
        OverlayAlert.queue!(type: "custom", title: "Test", message: "Message")
      }.to change(OverlayAlert, :count).by(1)
    end

    it "sets alert attributes" do
      alert = OverlayAlert.queue!(
        type: "subscriber",
        title: "New Sub!",
        message: "Welcome!",
        data: {username: "testuser"}
      )

      expect(alert.alert_type).to eq("subscriber")
      expect(alert.title).to eq("New Sub!")
      expect(alert.message).to eq("Welcome!")
      expect(alert.data).to eq({"username" => "testuser"})
    end

    it "sets expires_at when expires_in provided" do
      before = Time.current
      alert = OverlayAlert.queue!(type: "custom", expires_in: 10.seconds)
      after = Time.current

      expect(alert.expires_at).to be >= before + 10.seconds
      expect(alert.expires_at).to be <= after + 10.seconds
    end

    it "broadcasts to overlay channel" do
      expect(ActionCable.server).to receive(:broadcast).with(
        "overlay_updates",
        hash_including(type: "new_alert")
      )

      OverlayAlert.queue!(type: "custom")
    end

    it "returns the created alert" do
      alert = OverlayAlert.queue!(type: "custom")
      expect(alert).to be_a(OverlayAlert)
      expect(alert).to be_persisted
    end
  end

  describe "#mark_displayed!" do
    it "marks alert as displayed" do
      alert = create(:overlay_alert, displayed: false)

      before = Time.current
      alert.mark_displayed!
      after = Time.current

      expect(alert.displayed).to be true
      expect(alert.displayed_at).to be >= before
      expect(alert.displayed_at).to be <= after
    end
  end

  describe "#expired?" do
    it "returns true when expires_at is in the past" do
      alert = build(:overlay_alert, expires_at: 1.hour.ago)
      expect(alert.expired?).to be true
    end

    it "returns false when expires_at is in the future" do
      alert = build(:overlay_alert, expires_at: 1.hour.from_now)
      expect(alert.expired?).to be false
    end

    it "returns false when expires_at is nil" do
      alert = build(:overlay_alert, expires_at: nil)
      expect(alert.expired?).to be false
    end
  end

  describe "#as_broadcast_json" do
    it "returns correct structure" do
      alert = create(:overlay_alert,
        alert_type: "subscriber",
        title: "New Sub!",
        message: "Welcome!",
        data: {username: "test"})

      json = alert.as_broadcast_json

      expect(json[:id]).to eq(alert.id)
      expect(json[:alert_type]).to eq("subscriber")
      expect(json[:title]).to eq("New Sub!")
      expect(json[:message]).to eq("Welcome!")
      expect(json[:data]).to eq({"username" => "test"})
      expect(json[:created_at]).to eq(alert.created_at.iso8601)
    end
  end
end
