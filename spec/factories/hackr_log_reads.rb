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
FactoryBot.define do
  factory :hackr_log_read do
    association :grid_hackr
    association :hackr_log
    read_at { Time.current }
  end
end
