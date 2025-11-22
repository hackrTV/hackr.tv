require "rails_helper"

RSpec.describe Pulse, type: :model do
  describe "associations" do
    it { should belong_to(:grid_hackr) }
    it { should belong_to(:parent_pulse).optional }
    it { should belong_to(:thread_root).optional }
    it { should have_many(:echoes).dependent(:destroy) }
    it { should have_many(:splices).dependent(:destroy) }
    it { should have_many(:hackrs_who_echoed).through(:echoes) }
  end

  describe "validations" do
    it { should validate_presence_of(:content) }
    it { should validate_length_of(:content).is_at_most(256) }

    it "validates content cannot exceed 256 characters" do
      pulse = build(:pulse, content: "a" * 257)
      expect(pulse).not_to be_valid
      expect(pulse.errors[:content]).to include("is too long (maximum is 256 characters)")
    end

    it "allows content up to 256 characters" do
      pulse = build(:pulse, content: "a" * 256)
      expect(pulse).to be_valid
    end

    it "prevents splicing a signal-dropped pulse" do
      parent = create(:pulse, :signal_dropped)
      splice = build(:pulse, parent_pulse: parent)

      expect(splice).not_to be_valid
      expect(splice.errors[:parent_pulse_id]).to include("cannot splice a signal-dropped pulse")
    end

    it "allows splicing an active pulse" do
      parent = create(:pulse)
      splice = build(:pulse, parent_pulse: parent)

      expect(splice).to be_valid
    end
  end

  describe "callbacks" do
    describe "#set_pulsed_at" do
      it "sets pulsed_at automatically on create" do
        pulse = build(:pulse, pulsed_at: nil)
        expect(pulse.pulsed_at).to be_nil

        pulse.save
        expect(pulse.pulsed_at).to be_present
        expect(pulse.pulsed_at).to be_within(1.second).of(Time.current)
      end

      it "does not override manually set pulsed_at" do
        past_time = 2.hours.ago
        pulse = create(:pulse, pulsed_at: past_time)
        expect(pulse.pulsed_at).to be_within(1.second).of(past_time)
      end
    end

    describe "#set_thread_root" do
      it "sets thread_root_id to parent_id when splicing a root pulse" do
        root = create(:pulse)
        splice = create(:pulse, parent_pulse: root)

        expect(splice.thread_root_id).to eq(root.id)
      end

      it "inherits thread_root_id when splicing a splice" do
        root = create(:pulse)
        splice1 = create(:pulse, parent_pulse: root)
        splice2 = create(:pulse, parent_pulse: splice1)

        expect(splice2.thread_root_id).to eq(root.id)
      end

      it "does not set thread_root_id for root pulses" do
        root = create(:pulse)
        expect(root.thread_root_id).to be_nil
      end
    end
  end

  describe "scopes" do
    describe ".active" do
      it "returns only non-signal-dropped pulses" do
        active1 = create(:pulse)
        active2 = create(:pulse)
        create(:pulse, :signal_dropped)

        expect(Pulse.active).to contain_exactly(active1, active2)
      end
    end

    describe ".dropped" do
      it "returns only signal-dropped pulses" do
        create(:pulse)
        dropped1 = create(:pulse, :signal_dropped)
        dropped2 = create(:pulse, :signal_dropped)

        expect(Pulse.dropped).to contain_exactly(dropped1, dropped2)
      end
    end

    describe ".timeline" do
      it "orders pulses by pulsed_at descending" do
        pulse1 = create(:pulse, pulsed_at: 3.hours.ago)
        pulse2 = create(:pulse, pulsed_at: 1.hour.ago)
        pulse3 = create(:pulse, pulsed_at: 2.hours.ago)

        expect(Pulse.timeline.to_a).to eq([pulse2, pulse3, pulse1])
      end
    end

    describe ".roots" do
      it "returns only pulses without parents" do
        root1 = create(:pulse)
        root2 = create(:pulse)
        create(:pulse, parent_pulse: root1)

        expect(Pulse.roots).to contain_exactly(root1, root2)
      end
    end

    describe ".splices_for" do
      it "returns splices for a specific pulse ordered by time ascending" do
        root = create(:pulse)
        splice1 = create(:pulse, parent_pulse: root, pulsed_at: 2.hours.ago)
        splice2 = create(:pulse, parent_pulse: root, pulsed_at: 1.hour.ago)
        create(:pulse, parent_pulse: create(:pulse))

        expect(Pulse.splices_for(root.id)).to eq([splice1, splice2])
      end
    end
  end

  describe "#is_splice?" do
    it "returns true if pulse has a parent" do
      parent = create(:pulse)
      splice = create(:pulse, parent_pulse: parent)

      expect(splice.is_splice?).to be true
    end

    it "returns false if pulse has no parent" do
      root = create(:pulse)
      expect(root.is_splice?).to be false
    end
  end

  describe "#is_echo_by?" do
    it "returns true if hackr has echoed the pulse" do
      pulse = create(:pulse)
      hackr = create(:grid_hackr)
      create(:echo, pulse: pulse, grid_hackr: hackr)

      expect(pulse.is_echo_by?(hackr)).to be true
    end

    it "returns false if hackr has not echoed the pulse" do
      pulse = create(:pulse)
      hackr = create(:grid_hackr)

      expect(pulse.is_echo_by?(hackr)).to be false
    end

    it "returns false if hackr is nil" do
      pulse = create(:pulse)
      expect(pulse.is_echo_by?(nil)).to be false
    end
  end

  describe "#signal_drop!" do
    it "marks pulse as signal_dropped and sets timestamp" do
      pulse = create(:pulse)
      expect(pulse.signal_dropped).to be false

      pulse.signal_drop!
      pulse.reload

      expect(pulse.signal_dropped).to be true
      expect(pulse.signal_dropped_at).to be_within(1.second).of(Time.current)
    end
  end

  describe "#restore!" do
    it "unmarks signal_dropped and clears timestamp" do
      pulse = create(:pulse, :signal_dropped)
      expect(pulse.signal_dropped).to be true

      pulse.restore!
      pulse.reload

      expect(pulse.signal_dropped).to be false
      expect(pulse.signal_dropped_at).to be_nil
    end
  end

  describe "#thread_pulses" do
    it "returns all pulses in the same thread" do
      root = create(:pulse)
      splice1 = create(:pulse, parent_pulse: root)
      splice2 = create(:pulse, parent_pulse: splice1)
      other_root = create(:pulse)

      thread_pulses = root.thread_pulses.to_a
      expect(thread_pulses).to include(root, splice1, splice2)
      expect(thread_pulses).not_to include(other_root)
    end

    it "returns only self if pulse is not part of a thread" do
      lone_pulse = create(:pulse)
      expect(lone_pulse.thread_pulses.to_a).to eq([lone_pulse])
    end
  end
end
