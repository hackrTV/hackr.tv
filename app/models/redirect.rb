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
    normalized = path.chomp("/")
    normalized = "/" if normalized.empty?

    by_domain = where("domain = ? OR domain IS NULL", domain&.downcase)
      .order(Arel.sql("domain DESC NULLS LAST"))

    by_domain.where("LOWER(path) = LOWER(?)", path).first ||
      ((path != normalized) ? by_domain.where("LOWER(path) = LOWER(?)", normalized).first : nil)
  end
end
