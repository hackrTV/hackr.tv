# == Schema Information
#
# Table name: chat_channels
# Database name: primary
#
#  id                  :integer          not null, primary key
#  description         :text
#  is_active           :boolean          default(TRUE), not null
#  minimum_role        :string           default("operative"), not null
#  name                :string           not null
#  requires_livestream :boolean          default(FALSE), not null
#  slow_mode_seconds   :integer          default(0), not null
#  slug                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_chat_channels_on_is_active  (is_active)
#  index_chat_channels_on_slug       (slug) UNIQUE
#
require "rails_helper"

RSpec.describe ChatChannel, type: :model do
  describe "validations" do
    subject { build(:chat_channel) }

    it { should validate_presence_of(:slug) }
    it { should validate_presence_of(:name) }
    it { should validate_uniqueness_of(:slug) }

    it "validates minimum_role is a valid role" do
      channel = build(:chat_channel, minimum_role: "invalid")
      expect(channel).not_to be_valid
      expect(channel.errors[:minimum_role]).to be_present
    end

    it "accepts valid roles for minimum_role" do
      GridHackr::ROLE_LEVELS.keys.each do |role|
        channel = build(:chat_channel, minimum_role: role)
        expect(channel).to be_valid
      end
    end
  end

  describe "associations" do
    it { should have_many(:chat_messages).dependent(:destroy) }
  end

  describe "scopes" do
    describe ".active" do
      it "returns only active channels" do
        active = create(:chat_channel, is_active: true)
        create(:chat_channel, is_active: false)

        expect(ChatChannel.active).to contain_exactly(active)
      end
    end
  end

  describe "#stream_name" do
    it "returns the correct stream name" do
      channel = create(:chat_channel, slug: "ambient")
      expect(channel.stream_name).to eq("uplink:ambient")
    end
  end

  describe "#currently_available?" do
    context "when channel is inactive" do
      it "returns false" do
        channel = create(:chat_channel, :inactive)
        expect(channel.currently_available?).to be false
      end
    end

    context "when channel does not require livestream" do
      it "returns true if active" do
        channel = create(:chat_channel, is_active: true, requires_livestream: false)
        expect(channel.currently_available?).to be true
      end
    end

    context "when channel requires livestream" do
      let(:channel) { create(:chat_channel, :livestream_only) }

      it "returns false when no stream is live" do
        expect(channel.currently_available?).to be false
      end

      it "returns true when a stream is live" do
        create(:hackr_stream, :live)
        expect(channel.currently_available?).to be true
      end
    end
  end

  describe "#accessible_by?" do
    let(:operative) { create(:grid_hackr, role: "operative") }
    let(:operator) { create(:grid_hackr, :operator) }
    let(:admin) { create(:grid_hackr, :admin) }

    context "when hackr is nil" do
      it "returns false" do
        channel = create(:chat_channel)
        expect(channel.accessible_by?(nil)).to be false
      end
    end

    context "when channel is not currently available" do
      it "returns false" do
        channel = create(:chat_channel, :inactive)
        expect(channel.accessible_by?(operative)).to be false
      end
    end

    context "with minimum_role of operative" do
      let(:channel) { create(:chat_channel, minimum_role: "operative") }

      it "allows operatives" do
        expect(channel.accessible_by?(operative)).to be true
      end

      it "allows operators" do
        expect(channel.accessible_by?(operator)).to be true
      end

      it "allows admins" do
        expect(channel.accessible_by?(admin)).to be true
      end
    end

    context "with minimum_role of operator" do
      let(:channel) { create(:chat_channel, :operator_only) }

      it "denies operatives" do
        expect(channel.accessible_by?(operative)).to be false
      end

      it "allows operators" do
        expect(channel.accessible_by?(operator)).to be true
      end

      it "allows admins" do
        expect(channel.accessible_by?(admin)).to be true
      end
    end

    context "with minimum_role of admin" do
      let(:channel) { create(:chat_channel, :admin_only) }

      it "denies operatives" do
        expect(channel.accessible_by?(operative)).to be false
      end

      it "denies operators" do
        expect(channel.accessible_by?(operator)).to be false
      end

      it "allows admins" do
        expect(channel.accessible_by?(admin)).to be true
      end
    end
  end
end
