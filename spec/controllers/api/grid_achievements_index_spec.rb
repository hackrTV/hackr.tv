require "rails_helper"

# Dedicated spec for GET /api/grid/achievements — the endpoint
# powering the /achievements SPA status page. Kept separate from the
# pre-existing grid_controller_spec (auth flow focused) to isolate
# the achievement concerns.
RSpec.describe Api::GridController, type: :controller do
  describe "GET #achievements_index" do
    context "with no logged-in hackr" do
      it "returns 401 unauthorized" do
        get :achievements_index, format: :json
        expect(response).to have_http_status(:unauthorized)
      end
    end

    context "with a logged-in hackr" do
      let(:hackr) { create(:grid_hackr) }
      before { session[:grid_hackr_id] = hackr.id }

      it "returns achievements grouped by category with earned+progress per row" do
        create(:grid_achievement,
          slug: "music-10",
          category: "music",
          trigger_type: "track_plays_count",
          trigger_data: {"count" => 10},
          xp_reward: 25,
          cred_reward: 1)

        earned = create(:grid_achievement,
          slug: "music-1",
          category: "music",
          trigger_type: "track_plays_count",
          trigger_data: {"count" => 1},
          xp_reward: 10)
        create(:grid_hackr_achievement, grid_hackr: hackr, grid_achievement: earned, awarded_at: Time.current)

        get :achievements_index, format: :json

        expect(response).to have_http_status(:ok)
        json = JSON.parse(response.body)
        expect(json).to have_key("categories")
        expect(json).to have_key("summary")
        expect(json["categories"]).to have_key("music")

        music_rows = json["categories"]["music"]
        slugs = music_rows.map { |r| r["slug"] }
        expect(slugs).to contain_exactly("music-1", "music-10")

        earned_row = music_rows.find { |r| r["slug"] == "music-1" }
        expect(earned_row["earned"]).to be true
        expect(earned_row["awarded_at"]).to be_present

        unearned_row = music_rows.find { |r| r["slug"] == "music-10" }
        expect(unearned_row["earned"]).to be false
        expect(unearned_row["awarded_at"]).to be_nil
        # Progress shape is computed by the checker and should be present
        # for cumulative triggers.
        expect(unearned_row["progress"]).to include("current", "target", "fraction", "completed")
        expect(unearned_row["progress"]["target"]).to eq(10)
      end

      it "hides unearned hidden achievements from the payload" do
        create(:grid_achievement, slug: "secret", category: "grid",
          trigger_type: "manual", trigger_data: {}, hidden: true)

        get :achievements_index, format: :json

        json = JSON.parse(response.body)
        all_slugs = json["categories"].values.flatten.map { |r| r["slug"] }
        expect(all_slugs).not_to include("secret")
      end

      it "includes hidden achievements in the payload once earned" do
        hidden = create(:grid_achievement, slug: "secret-earned", category: "grid",
          trigger_type: "manual", trigger_data: {}, hidden: true)
        create(:grid_hackr_achievement, grid_hackr: hackr, grid_achievement: hidden, awarded_at: Time.current)

        get :achievements_index, format: :json

        json = JSON.parse(response.body)
        all_slugs = json["categories"].values.flatten.map { |r| r["slug"] }
        expect(all_slugs).to include("secret-earned")
      end

      it "reports earned/total in the summary block" do
        create(:grid_achievement, slug: "a", category: "grid", trigger_type: "manual", trigger_data: {})
        a_earned = create(:grid_achievement, slug: "b", category: "grid", trigger_type: "manual", trigger_data: {})
        create(:grid_hackr_achievement, grid_hackr: hackr, grid_achievement: a_earned, awarded_at: Time.current)

        get :achievements_index, format: :json

        json = JSON.parse(response.body)
        expect(json["summary"]["total"]).to eq({"total" => 2, "earned" => 1})
        expect(json["summary"]["by_category"]["grid"]).to eq({"total" => 2, "earned" => 1})
      end
    end
  end
end
