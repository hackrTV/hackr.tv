require "rails_helper"

RSpec.describe "Api::Grid#debit", type: :request do
  let!(:admin_hackr) { create(:grid_hackr, :admin) }
  let!(:raw_token) { admin_hackr.generate_api_token! }
  let(:admin_headers) { admin_headers_for(admin_hackr, raw_token) }

  let!(:target_hackr) { create(:grid_hackr) }
  let!(:target_cache) { create(:grid_cache, :default, grid_hackr: target_hackr) }
  let!(:redemption_cache) { create(:grid_cache, :redemption) }

  def fund_cache(cache, amount)
    source = create(:grid_cache)
    GridTransaction.create!(
      from_cache: source, to_cache: cache, amount: amount,
      tx_type: "genesis", tx_hash: SecureRandom.hex(32), created_at: Time.current
    )
  end

  describe "POST /api/grid/debit" do
    context "with valid admin credentials and sufficient balance" do
      before { fund_cache(target_cache, 500) }

      it "debits CRED from the hackr's default cache" do
        post "/api/grid/debit",
          params: {hackr_alias: target_hackr.hackr_alias, amount: 100, memo: "Redeem: TTS"},
          headers: admin_headers

        expect(response).to have_http_status(:ok)
        body = JSON.parse(response.body)
        expect(body["success"]).to be true
        expect(body["tx_hash"]).to be_present
        expect(body["remaining_balance"]).to eq(400)
      end

      it "creates a redemption transaction on the ledger" do
        expect {
          post "/api/grid/debit",
            params: {hackr_alias: target_hackr.hackr_alias, amount: 50, memo: "Redeem: Sound"},
            headers: admin_headers
        }.to change(GridTransaction, :count).by(1)

        tx = GridTransaction.last
        expect(tx.tx_type).to eq("redemption")
        expect(tx.from_cache).to eq(target_cache)
        expect(tx.to_cache).to eq(redemption_cache)
        expect(tx.amount).to eq(50)
        expect(tx.memo).to eq("Redeem: Sound")
      end
    end

    context "with insufficient balance" do
      before { fund_cache(target_cache, 10) }

      it "returns error with current balance" do
        post "/api/grid/debit",
          params: {hackr_alias: target_hackr.hackr_alias, amount: 100, memo: "Too expensive"},
          headers: admin_headers

        expect(response).to have_http_status(:unprocessable_entity)
        body = JSON.parse(response.body)
        expect(body["success"]).to be false
        expect(body["error"]).to match(/insufficient/i)
        expect(body["balance"]).to eq(10)
      end

      it "does not create a transaction" do
        expect {
          post "/api/grid/debit",
            params: {hackr_alias: target_hackr.hackr_alias, amount: 100, memo: "Nope"},
            headers: admin_headers
        }.not_to change(GridTransaction, :count)
      end
    end

    context "with invalid hackr alias" do
      it "returns 404" do
        post "/api/grid/debit",
          params: {hackr_alias: "nonexistent", amount: 10, memo: "Test"},
          headers: admin_headers

        expect(response).to have_http_status(:not_found)
        body = JSON.parse(response.body)
        expect(body["success"]).to be false
      end
    end

    context "with invalid amount" do
      it "rejects zero amount" do
        post "/api/grid/debit",
          params: {hackr_alias: target_hackr.hackr_alias, amount: 0, memo: "Zero"},
          headers: admin_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end

      it "rejects negative amount" do
        post "/api/grid/debit",
          params: {hackr_alias: target_hackr.hackr_alias, amount: -10, memo: "Negative"},
          headers: admin_headers

        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "without admin credentials" do
      let!(:operative) { create(:grid_hackr) }
      let!(:operative_token) { operative.generate_api_token! }
      let(:operative_headers) { admin_headers_for(operative, operative_token) }

      it "rejects non-admin hackrs" do
        post "/api/grid/debit",
          params: {hackr_alias: target_hackr.hackr_alias, amount: 10, memo: "Nope"},
          headers: operative_headers

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "without any credentials" do
      it "rejects unauthenticated requests" do
        post "/api/grid/debit",
          params: {hackr_alias: target_hackr.hackr_alias, amount: 10, memo: "Nope"}

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
