# == Schema Information
#
# Table name: hackr_log_reads
# Database name: primary
#
#  id            :integer          not null, primary key
#  read_at       :datetime         not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#  hackr_log_id  :integer          not null
#
# Indexes
#
#  index_hackr_log_reads_on_grid_hackr_id  (grid_hackr_id)
#  index_hackr_log_reads_on_hackr_log_id   (hackr_log_id)
#  index_hackr_log_reads_unique            (grid_hackr_id,hackr_log_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#  hackr_log_id   (hackr_log_id => hackr_logs.id)
#
require "rails_helper"

RSpec.describe HackrLogRead do
  let(:hackr) { create(:grid_hackr) }
  let(:log) { create(:hackr_log, :published) }

  describe ".record!" do
    it "creates a row on first call" do
      expect { described_class.record!(hackr, log) }
        .to change { described_class.count }.by(1)
    end

    it "is idempotent for the same hackr+log" do
      described_class.record!(hackr, log)
      expect { described_class.record!(hackr, log) }
        .not_to change { described_class.count }
    end

    it "enforces uniqueness at the model validation level" do
      described_class.create!(grid_hackr: hackr, hackr_log: log, read_at: Time.current)
      dup = described_class.new(grid_hackr: hackr, hackr_log: log, read_at: Time.current)
      expect(dup).not_to be_valid
    end
  end
end
