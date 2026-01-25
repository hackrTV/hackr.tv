# == Schema Information
#
# Table name: codex_entries
# Database name: primary
#
#  id         :integer          not null, primary key
#  content    :text
#  entry_type :string           not null
#  metadata   :json
#  name       :string           not null
#  position   :integer
#  published  :boolean          default(FALSE), not null
#  slug       :string           not null
#  summary    :text
#  created_at :datetime         not null
#  updated_at :datetime         not null
#
# Indexes
#
#  index_codex_entries_on_entry_type  (entry_type)
#  index_codex_entries_on_published   (published)
#  index_codex_entries_on_slug        (slug) UNIQUE
#
require "rails_helper"

RSpec.describe CodexEntry, type: :model do
  pending "add some examples to (or delete) #{__FILE__}"
end
