# == Schema Information
#
# Table name: redirects
# Database name: primary
#
#  id              :integer          not null, primary key
#  destination_url :string
#  domain          :string
#  path            :string
#  created_at      :datetime         not null
#  updated_at      :datetime         not null
#
# Indexes
#
#  index_redirects_on_domain_and_path  (domain,path) UNIQUE
#
class Redirect < ApplicationRecord
  validates :destination_url, presence: true
  validates :path, presence: true, uniqueness: {scope: :domain}

  # Find redirect by domain and path (case-insensitive)
  def self.find_for(domain, path)
    where("domain = ? OR domain IS NULL", domain&.downcase)
      .where("LOWER(path) = LOWER(?)", path)
      .order(Arel.sql("domain DESC NULLS LAST"))
      .first
  end
end
