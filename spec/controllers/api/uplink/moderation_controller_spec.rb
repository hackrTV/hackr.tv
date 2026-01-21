require "rails_helper"

RSpec.describe Api::Uplink::ModerationController, type: :controller do
  let(:hackr) { create(:grid_hackr) }
  let(:target_hackr) { create(:grid_hackr) }
  let(:operator) { create(:grid_hackr, :operator) }
  let(:admin) { create(:grid_hackr, :admin) }

  describe "POST #squelch" do
    context "when authenticated as operator" do
      before { session[:grid_hackr_id] = operator.id }

      it "squelches the target user" do
        expect {
          post :squelch, params: {id: target_hackr.id, reason: "Spam"}, format: :json
        }.to change { UserPunishment.squelched?(target_hackr) }.from(false).to(true)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
      end

      it "accepts duration_minutes parameter" do
        post :squelch, params: {id: target_hackr.id, duration_minutes: 30}, format: :json

        expect(response).to have_http_status(:success)
        punishment = UserPunishment.last
        expect(punishment.expires_at).to be_within(1.second).of(30.minutes.from_now)
      end

      it "returns 404 for non-existent user" do
        post :squelch, params: {id: 99999}, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as regular user" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns 403 forbidden" do
        post :squelch, params: {id: target_hackr.id}, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        post :squelch, params: {id: target_hackr.id}, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "POST #blackout" do
    context "when authenticated as admin" do
      before { session[:grid_hackr_id] = admin.id }

      it "blackouts the target user" do
        expect {
          post :blackout, params: {id: target_hackr.id, reason: "Harassment"}, format: :json
        }.to change { UserPunishment.blackouted?(target_hackr) }.from(false).to(true)

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true
      end
    end

    context "when authenticated as operator" do
      before { session[:grid_hackr_id] = operator.id }

      it "returns 403 forbidden (blackout requires admin)" do
        post :blackout, params: {id: target_hackr.id}, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        post :blackout, params: {id: target_hackr.id}, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end

  describe "DELETE #lift_punishment" do
    let!(:punishment) { create(:user_punishment, :squelch, grid_hackr: target_hackr) }

    context "when authenticated as operator" do
      before { session[:grid_hackr_id] = operator.id }

      it "lifts the punishment" do
        delete :lift_punishment, params: {id: target_hackr.id}, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["success"]).to be true

        expect(UserPunishment.exists?(punishment.id)).to be false
      end

      it "returns 404 if user has no active punishment" do
        punishment.lift!(admin)

        delete :lift_punishment, params: {id: target_hackr.id}, format: :json

        expect(response).to have_http_status(:not_found)
      end
    end

    context "when authenticated as regular user" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns 403 forbidden" do
        delete :lift_punishment, params: {id: target_hackr.id}, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end
  end

  describe "GET #moderation_log" do
    before do
      create(:moderation_log, actor: operator, target: target_hackr, action: "squelch")
      create(:moderation_log, actor: admin, target: hackr, action: "blackout")
    end

    context "when authenticated as operator" do
      before { session[:grid_hackr_id] = operator.id }

      it "returns moderation logs" do
        get :moderation_log, format: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["logs"].length).to eq(2)
      end

      it "paginates results" do
        get :moderation_log, params: {page: 1, per_page: 20}, format: :json

        json = JSON.parse(response.body)
        expect(json["meta"]["total"]).to eq(2)
      end

      it "orders by most recent first" do
        get :moderation_log, format: :json

        json = JSON.parse(response.body)
        timestamps = json["logs"].map { |l| l["created_at"] }
        expect(timestamps).to eq(timestamps.sort.reverse)
      end
    end

    context "when authenticated as regular user" do
      before { session[:grid_hackr_id] = hackr.id }

      it "returns 403 forbidden" do
        get :moderation_log, format: :json

        expect(response).to have_http_status(:forbidden)
      end
    end

    context "when not authenticated" do
      it "returns 401 unauthorized" do
        get :moderation_log, format: :json

        expect(response).to have_http_status(:unauthorized)
      end
    end
  end
end
