require "rails_helper"

RSpec.describe Api::GridController, type: :controller do
  describe "POST #login" do
    let!(:hackr) { create(:grid_hackr, hackr_alias: "TestHackr", password: "hackthegrid") }

    context "when prerelease mode is active" do
      before do
        stub_const("APP_SETTINGS", {prerelease_mode: "alpha", prerelease_banner_text: "Test banner"}.freeze)
      end

      it "still allows login for existing users" do
        post :login, params: {
          hackr_alias: "TestHackr",
          password: "hackthegrid"
        }, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json["success"]).to eq(true)
      end
    end

    describe "auth logging" do
      it "logs successful login" do
        allow(Rails.logger).to receive(:info).and_call_original
        expect(Rails.logger).to receive(:info).with(/\[AUTH\] Login success: hackr_alias=TestHackr ip=/)

        post :login, params: {
          hackr_alias: "TestHackr",
          password: "hackthegrid"
        }, format: :json
      end

      it "logs failed login with invalid password" do
        allow(Rails.logger).to receive(:warn).and_call_original
        expect(Rails.logger).to receive(:warn).with(/\[AUTH\] Login failed: attempted_alias=TestHackr reason=invalid_password ip=/)

        post :login, params: {
          hackr_alias: "TestHackr",
          password: "wrongpassword"
        }, format: :json
      end

      it "logs failed login with unknown alias" do
        allow(Rails.logger).to receive(:warn).and_call_original
        expect(Rails.logger).to receive(:warn).with(/\[AUTH\] Login failed: attempted_alias=UnknownHackr reason=unknown_alias ip=/)

        post :login, params: {
          hackr_alias: "UnknownHackr",
          password: "hackthegrid"
        }, format: :json
      end

      it "truncates long alias attempts in logs" do
        long_alias = "A" * 100
        allow(Rails.logger).to receive(:warn).and_call_original
        expect(Rails.logger).to receive(:warn).with(/attempted_alias=A{47}\.\.\./)

        post :login, params: {
          hackr_alias: long_alias,
          password: "hackthegrid"
        }, format: :json
      end
    end
  end
end
