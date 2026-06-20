require "rails_helper"

RSpec.describe "Vanity profile URLs", type: :request do
  it "redirects /@alias to the canonical /wire/alias" do
    get "/@xeraen"
    expect(response).to have_http_status(:moved_permanently)
    expect(response).to redirect_to("/wire/xeraen")
  end
end
