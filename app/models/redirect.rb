class Redirect < ApplicationRecord
  validates :destination_url, presence: true
  validates :path, presence: true, uniqueness: {scope: :domain}

  # Find redirect by domain and path
  def self.find_for(domain, path)
    where(domain: [domain, nil])
      .where(path: path)
      .order(Arel.sql("domain DESC NULLS LAST"))
      .first
  end
end
