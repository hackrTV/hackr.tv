# == Schema Information
#
# Table name: moderation_logs
# Database name: primary
#
#  id               :integer          not null, primary key
#  action           :string           not null
#  duration_minutes :integer
#  reason           :text
#  created_at       :datetime         not null
#  updated_at       :datetime         not null
#  actor_id         :integer          not null
#  chat_message_id  :integer
#  target_id        :integer
#
# Indexes
#
#  index_moderation_logs_on_action           (action)
#  index_moderation_logs_on_actor_id         (actor_id)
#  index_moderation_logs_on_chat_message_id  (chat_message_id)
#  index_moderation_logs_on_created_at       (created_at)
#  index_moderation_logs_on_target_id        (target_id)
#
# Foreign Keys
#
#  actor_id         (actor_id => grid_hackrs.id)
#  chat_message_id  (chat_message_id => chat_messages.id)
#  target_id        (target_id => grid_hackrs.id)
#
require "rails_helper"

RSpec.describe ModerationLog, type: :model do
  describe "validations" do
    it { should validate_presence_of(:action) }

    it "validates action is in allowed list" do
      log = build(:moderation_log, action: "invalid_action")
      expect(log).not_to be_valid
      expect(log.errors[:action]).to be_present
    end

    ModerationLog::ACTIONS.each do |valid_action|
      it "accepts '#{valid_action}' as a valid action" do
        log = build(:moderation_log, action: valid_action)
        expect(log).to be_valid
      end
    end
  end

  describe "associations" do
    it { should belong_to(:actor).class_name("GridHackr") }
    it { should belong_to(:target).class_name("GridHackr").optional }
    it { should belong_to(:chat_message).optional }
  end

  describe "scopes" do
    describe ".recent" do
      it "orders logs by created_at descending" do
        old = create(:moderation_log, created_at: 2.hours.ago)
        new = create(:moderation_log, created_at: 1.hour.ago)
        newest = create(:moderation_log, created_at: 30.minutes.ago)

        expect(ModerationLog.recent.to_a).to eq([newest, new, old])
      end
    end
  end

  describe ".log_action" do
    let(:actor) { create(:grid_hackr, :operator) }
    let(:target) { create(:grid_hackr) }

    it "creates a moderation log entry" do
      expect {
        ModerationLog.log_action(
          actor: actor,
          target: target,
          action: "squelch",
          reason: "Spam"
        )
      }.to change(ModerationLog, :count).by(1)
    end

    it "sets all provided attributes" do
      log = ModerationLog.log_action(
        actor: actor,
        target: target,
        action: "squelch",
        reason: "Spam",
        duration_minutes: 30
      )

      expect(log.actor).to eq(actor)
      expect(log.target).to eq(target)
      expect(log.action).to eq("squelch")
      expect(log.reason).to eq("Spam")
      expect(log.duration_minutes).to eq(30)
    end

    it "allows nil target" do
      log = ModerationLog.log_action(
        actor: actor,
        action: "drop_packet"
      )

      expect(log.target).to be_nil
      expect(log).to be_persisted
    end

    it "can associate with a chat message" do
      message = create(:chat_message)

      log = ModerationLog.log_action(
        actor: actor,
        action: "drop_packet",
        chat_message: message
      )

      expect(log.chat_message).to eq(message)
    end
  end
end
