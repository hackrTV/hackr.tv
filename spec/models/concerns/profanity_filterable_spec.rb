require "rails_helper"

RSpec.describe ProfanityFilterable do
  # Create a test class that includes the concern
  let(:test_class) do
    Class.new(ApplicationRecord) do
      self.table_name = "pulses"

      include ProfanityFilterable

      filter_profanity :content
    end
  end

  describe ".filter_profanity" do
    it "registers attributes for filtering" do
      expect(test_class.profanity_filtered_attributes).to include(:content)
    end
  end

  describe "#reject_profanity_content" do
    # Use actual Pulse model since the anonymous class approach has issues with associations
    let(:hackr) { create(:grid_hackr) }

    it "allows clean content" do
      pulse = build(:pulse, content: "Hello world", grid_hackr: hackr)
      expect(pulse).to be_valid
    end

    it "rejects content with common profanity" do
      pulse = build(:pulse, content: "This is bullshit", grid_hackr: hackr)
      expect(pulse).not_to be_valid
      expect(pulse.errors[:content]).to be_present
    end

    it "uses themed rejection message" do
      pulse = build(:pulse, content: "What the hell damn", grid_hackr: hackr)
      pulse.valid?
      expect(pulse.errors[:content].first).to start_with("GOVCORP CENSOR:")
    end

    it "skips blank content" do
      # Blank content should not trigger profanity check (other validations handle presence)
      pulse = build(:pulse, content: "", grid_hackr: hackr)
      pulse.valid?
      # Should not have profanity error (presence validation handles this)
      profanity_errors = pulse.errors[:content].select { |e| e.start_with?("GOVCORP CENSOR:") }
      expect(profanity_errors).to be_empty
    end

    it "rejects profanity with separator bypass attempts" do
      separators = %w[_ - . , ; : + / \\]
      separators.each do |sep|
        pulse = build(:pulse, content: "bull#{sep}shit", grid_hackr: hackr)
        expect(pulse).not_to be_valid, "Expected 'bull#{sep}shit' to be rejected"
        expect(pulse.errors[:content].first).to start_with("GOVCORP CENSOR:")
      end
    end
  end

  describe "REJECTION_MESSAGES" do
    it "contains multiple GovCorp themed messages" do
      expect(ProfanityFilterable::REJECTION_MESSAGES.length).to eq(5)
      ProfanityFilterable::REJECTION_MESSAGES.each do |msg|
        expect(msg).to start_with("GOVCORP CENSOR:")
      end
    end
  end

  describe ".rejection_message" do
    it "returns a message from the list" do
      message = ProfanityFilterable.rejection_message
      expect(ProfanityFilterable::REJECTION_MESSAGES).to include(message)
    end
  end
end
