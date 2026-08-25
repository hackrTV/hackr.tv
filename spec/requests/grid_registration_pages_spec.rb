require "rails_helper"

# Server-rendered registration (Hotwire migration Phase 2): email step,
# token verification, and completion.
RSpec.describe "Grid registration pages", type: :request do
  describe "GET /grid/register" do
    it "renders the email form" do
      get "/grid/register"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("JOIN THE FRACTURE NETWORK")
      expect(response.body).to include("SEND VERIFICATION")
    end
  end

  describe "POST /grid/register" do
    it "creates a token, mails it, and shows the inbox panel" do
      expect {
        post "/grid/register", params: {email: "NewHackr@example.com"}
      }.to change(GridRegistrationToken, :count).by(1)
        .and have_enqueued_mail(GridMailer, :registration_verification)

      expect(response).to redirect_to("/grid/register")
      follow_redirect!
      expect(response.body).to include("CHECK YOUR INBOX")
      expect(response.body).to include("newhackr@example.com")
      expect(GridRegistrationToken.last.email).to eq("newhackr@example.com")
    end

    it "rejects an invalid email" do
      post "/grid/register", params: {email: "not-an-email"}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Please enter a valid email address.")
    end

    it "rejects an already-registered email" do
      create(:grid_hackr, email: "taken@example.com")

      post "/grid/register", params: {email: "taken@example.com"}

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("This email address is already registered.")
    end
  end

  describe "GET /grid/verify/:token" do
    it "renders the completion form for a valid token" do
      token = GridRegistrationToken.create!(email: "fresh@example.com")

      get "/grid/verify/#{token.token}"

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("ALMOST THERE")
      expect(response.body).to include("fresh@example.com")
      expect(response.body).to include("JOIN GRID")
    end

    it "shows the failure panel for an unknown token" do
      get "/grid/verify/nope"

      expect(response.body).to include("VERIFICATION FAILED")
      expect(response.body).to include("Invalid verification link.")
    end

    it "shows the failure panel for used and expired tokens" do
      used = GridRegistrationToken.create!(email: "used@example.com")
      used.mark_used!
      get "/grid/verify/#{used.token}"
      expect(response.body).to include("This verification link has already been used.")

      expired = GridRegistrationToken.create!(email: "late@example.com")
      expired.update!(expires_at: 1.hour.ago)
      get "/grid/verify/#{expired.token}"
      expect(response.body).to include("This verification link has expired.")
    end
  end

  describe "POST /grid/verify/:token" do
    let!(:token) { GridRegistrationToken.create!(email: "join@example.com") }

    before do
      # provision_economy! needs base component definitions
      %w[basic-motherboard basic-psu basic-cpu basic-gpu basic-ram].each_with_index do |slug, i|
        slots = %w[motherboard psu cpu gpu ram]
        props = {"slot" => slots[i], "rate_multiplier" => 1.0}
        props.merge!("cpu_slots" => 1, "gpu_slots" => 2, "ram_slots" => 2) if slug == "basic-motherboard"
        create(:grid_item_definition, slug: slug, name: "Basic #{slots[i].capitalize}", item_type: "rig_component", properties: props)
      end
    end

    it "creates the hackr, logs in, and redirects to the grid" do
      expect {
        post "/grid/verify/#{token.token}", params: {
          hackr_alias: "FreshOperator",
          password: "S3cure-Pass!",
          password_confirmation: "S3cure-Pass!"
        }
      }.to change(GridHackr, :count).by(1)

      expect(response).to redirect_to("/grid")
      new_hackr = GridHackr.find_by(hackr_alias: "FreshOperator")
      expect(new_hackr.email).to eq("join@example.com")
      expect(session[:grid_hackr_id]).to eq(new_hackr.id)
      expect(token.reload).to be_used
    end

    it "re-renders the form with validation errors" do
      post "/grid/verify/#{token.token}", params: {
        hackr_alias: "abc", # below the 6-char minimum
        password: "S3cure-Pass!",
        password_confirmation: "S3cure-Pass!"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("Registration failed:")
      expect(response.body).to include("abc") # alias preserved
      expect(GridHackr.find_by(hackr_alias: "abc")).to be_nil
      expect(token.reload).not_to be_used
    end

    it "shows the failure panel when the token was already used" do
      token.mark_used!

      post "/grid/verify/#{token.token}", params: {
        hackr_alias: "FreshOperator",
        password: "S3cure-Pass!",
        password_confirmation: "S3cure-Pass!"
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include("This verification link has already been used.")
    end
  end
end
