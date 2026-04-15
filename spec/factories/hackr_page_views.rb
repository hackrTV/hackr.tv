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
FactoryBot.define do
  factory :hackr_page_view do
    association :grid_hackr
    page_type { "bio" }
    resource_id { 1 }
    viewed_at { Time.current }
  end
end
