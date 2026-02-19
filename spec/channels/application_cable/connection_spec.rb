require "rails_helper"

module ApplicationCable
  RSpec.describe Connection, type: :channel do
    let(:admin_hackr) { create(:grid_hackr, :admin, hackr_alias: "relay_test") }
    let(:operative_hackr) { create(:grid_hackr, hackr_alias: "operative_test") }
    let(:admin_token) { "test_admin_api_token_secret" }

    before do
      allow(ENV).to receive(:[]).and_call_original
      allow(ENV).to receive(:[]).with("HACKR_ADMIN_API_TOKEN").and_return(admin_token)
    end

    describe "cookie auth" do
      it "identifies hackr from encrypted cookie" do
        cookies.encrypted[:grid_hackr_id] = admin_hackr.id
        connect

        expect(connection.current_hackr).to eq(admin_hackr)
      end

      it "allows anonymous connection when no cookie" do
        connect

        expect(connection.current_hackr).to be_nil
      end
    end

    describe "admin token auth" do
      it "authenticates with valid token and admin alias" do
        connect params: {token: admin_token, hackr_alias: admin_hackr.hackr_alias}

        expect(connection.current_hackr).to eq(admin_hackr)
      end

      it "rejects when token does not match" do
        expect {
          connect params: {token: "wrong_token", hackr_alias: admin_hackr.hackr_alias}
        }.to have_rejected_connection
      end

      it "rejects when hackr_alias does not exist" do
        expect {
          connect params: {token: admin_token, hackr_alias: "nonexistent"}
        }.to have_rejected_connection
      end

      it "rejects when hackr_alias is not an admin" do
        expect {
          connect params: {token: admin_token, hackr_alias: operative_hackr.hackr_alias}
        }.to have_rejected_connection
      end

      it "rejects when token param is not a string" do
        expect {
          connect params: {token: ["array_value"], hackr_alias: admin_hackr.hackr_alias}
        }.to have_rejected_connection
      end

      it "rejects when HACKR_ADMIN_API_TOKEN env is not set" do
        allow(ENV).to receive(:[]).with("HACKR_ADMIN_API_TOKEN").and_return(nil)

        expect {
          connect params: {token: "any_token", hackr_alias: admin_hackr.hackr_alias}
        }.to have_rejected_connection
      end

      it "allows anonymous connection when only token is present without alias" do
        connect params: {token: admin_token}

        expect(connection.current_hackr).to be_nil
      end

      it "allows anonymous connection when only alias is present without token" do
        connect params: {hackr_alias: admin_hackr.hackr_alias}

        expect(connection.current_hackr).to be_nil
      end
    end

    describe "auth precedence" do
      it "prefers cookie auth over token auth" do
        cookies.encrypted[:grid_hackr_id] = operative_hackr.id
        connect params: {token: admin_token, hackr_alias: admin_hackr.hackr_alias}

        expect(connection.current_hackr).to eq(operative_hackr)
      end
    end
  end
end
