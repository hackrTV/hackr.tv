# == Schema Information
#
# Table name: chat_channels
# Database name: primary
#
#  id                  :integer          not null, primary key
#  category            :string           default("COMMS"), not null
#  description         :text
#  is_active           :boolean          default(TRUE), not null
#  minimum_role        :string           default("operative"), not null
#  name                :string           not null
#  position            :integer          default(0), not null
#  requires_livestream :boolean          default(FALSE), not null
#  slow_mode_seconds   :integer          default(0), not null
#  slug                :string           not null
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_chat_channels_on_is_active        (is_active)
#  index_chat_channels_on_position_and_id  (position,id)
#  index_chat_channels_on_slug             (slug) UNIQUE
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

  describe "sidebar category + position (Uplink shell)" do
    it "upcases and trims the category, defaulting blank to COMMS" do
      expect(create(:chat_channel, category: " broadcast ").category).to eq("BROADCAST")
      expect(create(:chat_channel, category: "").category).to eq("COMMS")
      expect(create(:chat_channel, category: nil).category).to eq("COMMS")
    end

    it "rejects categories with punctuation or over 24 chars" do
      expect(build(:chat_channel, category: "no/slash")).not_to be_valid
      expect(build(:chat_channel, category: "x" * 25)).not_to be_valid
      expect(build(:chat_channel, category: "OPS ROOM_2")).to be_valid
    end

    it "requires a non-negative integer position" do
      expect(build(:chat_channel, position: -1)).not_to be_valid
      expect(build(:chat_channel, position: 1.5)).not_to be_valid
      expect(build(:chat_channel, position: 0)).to be_valid
    end

    describe ".ordered" do
      it "sorts by position then id" do
        late = create(:chat_channel, position: 10)
        early = create(:chat_channel, position: 0)
        early_too = create(:chat_channel, position: 0)

        expect(ChatChannel.ordered.to_a).to eq([early, early_too, late])
      end
    end

    describe ".next_position" do
      it "lands after the current last channel, 0 when there are none" do
        expect(ChatChannel.next_position).to eq(0)
        create(:chat_channel, position: 10)
        expect(ChatChannel.next_position).to eq(20)
      end
    end

    describe "#move! (the /root/uplink ↑/↓)" do
      let!(:live) { create(:chat_channel, slug: "live", category: "BROADCAST", position: 0) }
      let!(:ambient) { create(:chat_channel, slug: "ambient", category: "COMMS", position: 0) }
      let!(:ops) { create(:chat_channel, slug: "ops", category: "COMMS", position: 0) }
      let!(:misc) { create(:chat_channel, slug: "misc", category: "COMMS", position: 0) }

      it "resolves ties by renumbering the sidebar order in steps of 10, then swaps with the neighbour inside the category" do
        expect(ops.move!("down")).to eq(misc)
        expect(ChatChannel.ordered.pluck(:slug, :position)).to eq([["live", 0], ["ambient", 10], ["misc", 20], ["ops", 30]])
        expect(ops.position).to eq(30)

        expect(ops.move!(:up)).to eq(misc)
        expect(ChatChannel.ordered.pluck(:slug)).to eq(%w[live ambient ops misc])
      end

      it "returns nil at the group's edge and never crosses into another heading (the renumbering alone changes no order)" do
        expect(live.move!("down")).to be_nil
        expect(ambient.move!("up")).to be_nil
        expect(ChatChannel.ordered.pluck(:slug, :position)).to eq([["live", 0], ["ambient", 10], ["ops", 20], ["misc", 30]])
      end

      it "keeps the headings in place when a group's first channel swaps down: the group's set of positions is unchanged" do
        ambient.update_column(:position, 0)
        live.update_column(:position, 10)
        ops.update_column(:position, 20)
        misc.update_column(:position, 30)
        expect(ChatChannel.ordered.group_by(&:category).keys).to eq(%w[COMMS BROADCAST])

        expect(ambient.move!("down")).to eq(ops)

        expect(ChatChannel.ordered.pluck(:slug, :position)).to eq([["ops", 0], ["live", 10], ["ambient", 20], ["misc", 30]])
        expect(ChatChannel.ordered.group_by(&:category).keys).to eq(%w[COMMS BROADCAST])
      end

      it "rejects an unknown direction" do
        expect { ops.move!("sideways") }.to raise_error(KeyError)
      end
    end
  end
end
