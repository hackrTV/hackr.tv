require "rails_helper"

RSpec.describe Echo, type: :model do
  describe "associations" do
    it { should belong_to(:pulse) }
    it { should belong_to(:grid_hackr) }
  end

  describe "validations" do
    subject { build(:echo) }

    it "validates uniqueness of grid_hackr_id scoped to pulse_id" do
      echo1 = create(:echo)
      echo2 = build(:echo, pulse: echo1.pulse, grid_hackr: echo1.grid_hackr)

      expect(echo2).not_to be_valid
      expect(echo2.errors[:grid_hackr_id]).to include("has already echoed this pulse")
    end

    it "allows same hackr to echo different pulses" do
      hackr = create(:grid_hackr)
      pulse1 = create(:pulse)
      pulse2 = create(:pulse)

      create(:echo, pulse: pulse1, grid_hackr: hackr)
      echo2 = build(:echo, pulse: pulse2, grid_hackr: hackr)

      expect(echo2).to be_valid
    end

    it "allows different hackrs to echo same pulse" do
      pulse = create(:pulse)
      hackr1 = create(:grid_hackr)
      hackr2 = create(:grid_hackr)

      create(:echo, pulse: pulse, grid_hackr: hackr1)
      echo2 = build(:echo, pulse: pulse, grid_hackr: hackr2)

      expect(echo2).to be_valid
    end
  end

  describe "callbacks" do
    describe "#set_echoed_at" do
      it "sets echoed_at automatically on create" do
        echo = build(:echo, echoed_at: nil)
        expect(echo.echoed_at).to be_nil

        echo.save
        expect(echo.echoed_at).to be_present
        expect(echo.echoed_at).to be_within(1.second).of(Time.current)
      end

      it "does not override manually set echoed_at" do
        past_time = 2.hours.ago
        echo = create(:echo, echoed_at: past_time)
        expect(echo.echoed_at).to be_within(1.second).of(past_time)
      end
    end
  end

  describe "counter cache" do
    it "increments pulse echo_count when echo is created" do
      pulse = create(:pulse)
      expect(pulse.echo_count).to eq(0)

      create(:echo, pulse: pulse)
      pulse.reload

      expect(pulse.echo_count).to eq(1)
    end

    it "decrements pulse echo_count when echo is destroyed" do
      pulse = create(:pulse)
      echo = create(:echo, pulse: pulse)
      pulse.reload
      expect(pulse.echo_count).to eq(1)

      echo.destroy
      pulse.reload

      expect(pulse.echo_count).to eq(0)
    end

    it "accurately counts multiple echoes" do
      pulse = create(:pulse)
      create(:echo, pulse: pulse)
      create(:echo, pulse: pulse)
      create(:echo, pulse: pulse)
      pulse.reload

      expect(pulse.echo_count).to eq(3)
    end
  end

  describe "scopes" do
    describe ".recent" do
      it "orders echoes by echoed_at descending" do
        echo1 = create(:echo, echoed_at: 3.hours.ago)
        echo2 = create(:echo, echoed_at: 1.hour.ago)
        echo3 = create(:echo, echoed_at: 2.hours.ago)

        expect(Echo.recent.to_a).to eq([echo2, echo3, echo1])
      end
    end
  end
end
