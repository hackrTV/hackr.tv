require "rails_helper"

RSpec.describe SentEmail, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:emailable).optional }
  end
end
