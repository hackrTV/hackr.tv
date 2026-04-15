# == Schema Information
#
# Table name: hackr_page_views
# Database name: primary
#
#  id            :integer          not null, primary key
#  page_type     :string           not null
#  viewed_at     :datetime         not null
#  created_at    :datetime         not null
#  updated_at    :datetime         not null
#  grid_hackr_id :integer          not null
#  resource_id   :integer          not null
#
# Indexes
#
#  index_hackr_page_views_hackr_type        (grid_hackr_id,page_type)
#  index_hackr_page_views_on_grid_hackr_id  (grid_hackr_id)
#  index_hackr_page_views_unique            (grid_hackr_id,page_type,resource_id) UNIQUE
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
require "rails_helper"

RSpec.describe HackrPageView do
  let(:hackr) { create(:grid_hackr) }
  let(:artist) { create(:artist) }

  describe "validations" do
    it "rejects unknown page_type" do
      view = described_class.new(grid_hackr: hackr, page_type: "bogus", resource_id: 1, viewed_at: Time.current)
      expect(view).not_to be_valid
    end

    it "accepts bio / release_index / release" do
      %w[bio release_index release].each do |type|
        view = described_class.new(grid_hackr: hackr, page_type: type, resource_id: 1, viewed_at: Time.current)
        expect(view).to be_valid
      end
    end
  end

  describe ".record!" do
    it "is idempotent per hackr+page_type+resource_id" do
      described_class.record!(hackr, "bio", artist.id)
      expect { described_class.record!(hackr, "bio", artist.id) }
        .not_to change { described_class.count }
    end

    it "allows the same hackr+resource under a different page_type" do
      described_class.record!(hackr, "bio", artist.id)
      expect { described_class.record!(hackr, "release_index", artist.id) }
        .to change { described_class.count }.by(1)
    end
  end
end
