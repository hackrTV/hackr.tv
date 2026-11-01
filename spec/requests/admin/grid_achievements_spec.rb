require "rails_helper"

# /root/grid_achievements — the achievements ledger (CATEGORY, FILTER,
# MANUAL AWARD) and the achievement record as console screens
# (console-ui-for-all-admin Phase 4, 2026-11-01).
RSpec.describe "Admin grid achievements", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_achievements"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the achievements as numbered ledger rows with CATEGORY, FILTER, manual awards, destinations and the prompt" do
    walker = create(:grid_achievement, name: "Street Walker", slug: "street-walker", category: "grid", trigger_type: "rooms_visited", badge_icon: ">>", xp_reward: 25, cred_reward: 5)
    create(:grid_hackr_achievement, grid_hackr: operative, grid_achievement: walker)
    medal = create(:grid_achievement, :manual, name: "Founders Medal", slug: "founders-medal", category: "meta", hidden: true)
    log_in!(admin)

    get "/root/grid_achievements"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 achievements", "1 award earned", "1 hidden", "1 manual")
    expect(body).to include("[01]", "[02]", 'data-command="02"', 'id="ledger-filter"')
    expect(body).to include('data-search="street walker street-walker grid rooms_visited"')
    expect(body).to include("/root/grid_achievements?category=music", "HIDDEN", "&gt;&gt;")
    expect(body).to include("/root/grid_achievements/#{walker.id}/edit", "/root/grid_achievements/#{walker.id}/history")
    expect(body).to include("// MANUAL AWARD //", "action=\"/root/grid_achievements/#{medal.id}/award\"", 'name="hackr_id"')
    expect(body).not_to include("action=\"/root/grid_achievements/#{walker.id}/award\"")
    expect(body).to include("[MISSIONS]", "[ROOT]")
    expect(body).not_to include("[ACHIEVEMENTS]")
    expect(body).to include("type an achievement number")
  end

  it "filters by a listed CATEGORY and ignores an unknown one" do
    create(:grid_achievement, name: "Street Walker", category: "grid")
    create(:grid_achievement, name: "Tuned In", category: "music")
    log_in!(admin)

    get "/root/grid_achievements", params: {category: "music"}
    expect(response.body).to include("Tuned In", "1 achievement · MUSIC")
    expect(response.body).not_to include("Street Walker")

    get "/root/grid_achievements", params: {category: "bogus"}
    expect(response.body).to include("Tuned In", "Street Walker", "2 achievements")
  end

  it "redirects show to the record screen" do
    achievement = create(:grid_achievement)
    log_in!(admin)

    get "/root/grid_achievements/#{achievement.id}"

    expect(response).to redirect_to("/root/grid_achievements/#{achievement.id}/edit")
  end

  it "renders the record with every field, the EARNED readout and the delete form" do
    achievement = create(:grid_achievement, name: "Street Walker", trigger_data: {"count" => 10})
    log_in!(admin)

    get "/root/grid_achievements/#{achievement.id}/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Street Walker"', "action=\"/root/grid_achievements/#{achievement.id}\"", "EARNED", "0 hackrs")
    %w[slug name badge_icon category trigger_type xp_reward cred_reward hidden description trigger_data_json].each do |field|
      expect(body).to include(%(name="grid_achievement[#{field}]"))
    end
    expect(body).to include("// TRIGGER DATA //", ERB::Util.html_escape('{"count":10}'))
    expect(body).to include('form="delete-achievement"', 'id="delete-achievement"')
  end

  it "saves every field and stays on the record" do
    achievement = create(:grid_achievement)
    log_in!(admin)

    patch "/root/grid_achievements/#{achievement.id}", params: {grid_achievement: {
      slug: "deep-diver", name: "Deep Diver", description: "D", badge_icon: "%", category: "progression",
      trigger_type: "manual", xp_reward: "40", cred_reward: "15", hidden: "1", trigger_data_json: '{"depth": 3}'
    }}

    expect(response).to redirect_to("/root/grid_achievements/#{achievement.id}/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Achievement 'Deep Diver' updated."))
    expect(achievement.reload).to have_attributes(slug: "deep-diver", name: "Deep Diver", description: "D", badge_icon: "%",
      category: "progression", trigger_type: "manual", xp_reward: 40, cred_reward: 15, hidden: true, trigger_data: {"depth" => 3})
  end

  it "rejects a negative XP with a 422 and the error on the field" do
    achievement = create(:grid_achievement)
    log_in!(admin)

    patch "/root/grid_achievements/#{achievement.id}", params: {grid_achievement: {xp_reward: "-1"}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", "must be greater than or equal to 0")
  end

  it "refuses TRIGGER DATA that is not a JSON object instead of saving it as {}" do
    achievement = create(:grid_achievement, trigger_data: {"count" => 10})
    log_in!(admin)

    patch "/root/grid_achievements/#{achievement.id}", params: {grid_achievement: {name: "Renamed", trigger_data_json: '{"count": 1'}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "Trigger data is not valid JSON", ERB::Util.html_escape('{"count": 1'))
    expect(achievement.reload).to have_attributes(name: achievement.name, trigger_data: {"count" => 10})

    patch "/root/grid_achievements/#{achievement.id}", params: {grid_achievement: {trigger_data_json: "[1, 2]"}}
    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("Trigger data must be a JSON object")
  end

  it "creates an achievement and opens its record; deletes it" do
    log_in!(admin)

    post "/root/grid_achievements", params: {grid_achievement: {slug: "fresh", name: "Fresh", category: "grid", trigger_type: "manual",
                                                                xp_reward: "0", cred_reward: "0", trigger_data_json: ""}}
    achievement = GridAchievement.find_by!(slug: "fresh")
    expect(response).to redirect_to("/root/grid_achievements/#{achievement.id}/edit")
    expect(achievement.trigger_data).to eq({})

    expect { delete "/root/grid_achievements/#{achievement.id}" }.to change(GridAchievement, :count).by(-1)
    expect(response).to redirect_to("/root/grid_achievements")
  end

  it "awards a manual achievement from the ledger, once" do
    medal = create(:grid_achievement, :manual, name: "Founders Medal")
    log_in!(admin)

    post "/root/grid_achievements/#{medal.id}/award", params: {hackr_id: operative.id}
    expect(response).to redirect_to("/root/grid_achievements")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Awarded 'Founders Medal' to #{operative.hackr_alias}."))

    post "/root/grid_achievements/#{medal.id}/award", params: {hackr_id: operative.id}
    follow_redirect!
    expect(response.body).to include("[ERR]", ERB::Util.html_escape("#{operative.hackr_alias} already has 'Founders Medal'."))
  end
end
