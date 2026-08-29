class PagesController < ApplicationController
  skip_forgery_protection only: :not_found

  def not_found
    render file: Rails.public_path.join("404.html"), layout: false, status: :not_found
  end
end
