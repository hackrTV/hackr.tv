# == Schema Information
#
# Table name: grid_factions
# Database name: primary
#
#  id           :integer          not null, primary key
#  color_scheme :string
#  description  :text
#  name         :string
#  slug         :string
#  created_at   :datetime         not null
#  updated_at   :datetime         not null
#  artist_id    :integer
#
require "rails_helper"

RSpec.describe GridFaction, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
