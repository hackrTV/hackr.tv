# == Schema Information
#
# Table name: hackr_streams
# Database name: primary
#
#  id         :integer          not null, primary key
#  ended_at   :datetime
#  is_live    :boolean          default(FALSE), not null
#  live_url   :string
#  started_at :datetime
#  title      :string
#  track_slug :string
#  vod_url    :string
#  created_at :datetime         not null
#  updated_at :datetime         not null
#  artist_id  :integer          not null
#
# Indexes
#
#  index_hackr_streams_on_artist_id  (artist_id)
#
# Foreign Keys
#
#  artist_id  (artist_id => artists.id)
#
require "rails_helper"

RSpec.describe HackrStream, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
