require "rails_helper"

# /root/grid_schematics — the schematics ledger and the schematic record
# as console screens (console-ui-for-all-admin Phase 4, 2026-11-01).
RSpec.describe "Admin grid schematics", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }
  let!(:output) { create(:grid_item_definition, name: "Signal Booster") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_schematics"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the schematics as numbered ledger rows with destinations and the prompt" do
    schematic = create(:grid_schematic, name: "Booster Kit", slug: "booster-kit", output_definition: output, output_quantity: 2, xp_reward: 40, required_clearance: 7, position: 0)
    create(:grid_schematic_ingredient, grid_schematic: schematic)
    create(:grid_schematic, :unpublished, name: "Draft Kit", position: 1)
    log_in!(admin)

    get "/root/grid_schematics"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 schematics", "1 live", "1 draft")
    expect(body).to include("[01]", "[02]", 'data-command="02"', "Signal Booster", "x2", "LIVE", "DRAFT")
    expect(body).to include("/root/grid_schematics/booster-kit/edit", "/root/grid_schematics/booster-kit/history")
    expect(body).to include("[ITEMS]", "[SHOPS]")
    expect(body).not_to include("[SCHEMATICS]", "turbo_method", "turbo-method")
    expect(body).to include("type a schematic number")
  end

  it "renders the record with the fields, gates, ingredient rows and the hooks the ingredient script targets" do
    schematic = create(:grid_schematic, name: "Booster Kit", slug: "booster-kit", output_definition: output, required_mission_slug: "signal-recovery")
    input = create(:grid_item_definition, name: "Copper Wire")
    create(:grid_schematic_ingredient, grid_schematic: schematic, input_definition: input, quantity: 3)
    log_in!(admin)

    get "/root/grid_schematics/booster-kit/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Booster Kit"', 'action="/root/grid_schematics/booster-kit"', 'name="grid_schematic[output_definition_id]"',
      'name="grid_schematic[published]"', 'value="signal-recovery"', 'name="grid_schematic[required_room_type]"')
    expect(body).to include("[&gt;] OUTPUT", "/root/grid_item_definitions/#{output.slug}/edit", "// GATES //")
    expect(body).to include("// INGREDIENTS //", 'id="ingredients-table"', 'id="add-ingredient-btn"', 'id="ingredient-row-template"', "ingredient-destroy-btn")
    expect(body).to include('name="grid_schematic[ingredients_attributes][0][quantity]"', 'class="destroy-flag"', 'data-persisted="true"')
    expect(body).to include('form="delete-schematic"', 'id="delete-schematic"')
    script = body[/<script nonce="[^"]*">\s*\(function\(\) \{\s*var ingredientRowIndex.*?<\/script>/m]
    expect(script).to include("closest('.rc-row')", "row.hidden = true")
    expect(script).not_to include("tui-", "style.")
  end

  it "saves every field and a new ingredient, and stays on the record" do
    schematic = create(:grid_schematic, slug: "old-kit", output_definition: output)
    other = create(:grid_item_definition)
    input = create(:grid_item_definition)
    log_in!(admin)

    patch "/root/grid_schematics/old-kit", params: {grid_schematic: {
      name: "Booster Kit", slug: "booster-kit", description: "D", output_definition_id: other.id.to_s, output_quantity: "3",
      xp_reward: "25", required_clearance: "9", position: "4", published: "0",
      required_mission_slug: "signal-recovery", required_achievement_slug: "first-salvage", required_room_type: "den",
      ingredients_attributes: {"1000" => {position: "0", input_definition_id: input.id.to_s, quantity: "2"}}
    }}

    expect(response).to redirect_to("/root/grid_schematics/booster-kit/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Schematic 'Booster Kit' updated."))
    expect(schematic.reload).to have_attributes(name: "Booster Kit", slug: "booster-kit", description: "D", output_definition_id: other.id,
      output_quantity: 3, xp_reward: 25, required_clearance: 9, position: 4, published: false,
      required_mission_slug: "signal-recovery", required_achievement_slug: "first-salvage", required_room_type: "den")
    expect(schematic.ingredients.map { |i| [i.input_definition_id, i.quantity] }).to eq([[input.id, 2]])
  end

  it "rejects an out-of-range clearance with a 422, the error on the field and a removed ingredient still flagged and hidden" do
    schematic = create(:grid_schematic, name: "Booster Kit", slug: "booster-kit", output_definition: output)
    ingredient = create(:grid_schematic_ingredient, grid_schematic: schematic)
    log_in!(admin)

    patch "/root/grid_schematics/booster-kit", params: {grid_schematic: {required_clearance: "120",
                                                                         ingredients_attributes: {"0" => {id: ingredient.id.to_s, _destroy: "1"}}}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to be_console_clean
    expect(response.body).to include("[ERR]", "rc-err", "less than or equal to 99")
    expect(response.body).to match(/<div class="rc-row" hidden="hidden">\s*<span><input[^>]*name="grid_schematic\[ingredients_attributes\]\[0\]\[position\]"/)
    expect(response.body[/<input(?=[^>]*name="grid_schematic\[ingredients_attributes\]\[0\]\[_destroy\]")[^>]*>/]).to include('value="1"')
    expect(schematic.ingredients.reload).to eq([ingredient])
  end

  it "creates a schematic and opens its record; deletes one through the hidden form" do
    log_in!(admin)

    get "/root/grid_schematics/new"
    expect(response.body).to be_console_clean
    expect(response.body).to include("NEW SCHEMATIC", 'id="ingredient-row-template"')

    post "/root/grid_schematics", params: {grid_schematic: {name: "Fresh", slug: "fresh", output_definition_id: output.id.to_s, output_quantity: "1", xp_reward: "0", required_clearance: "0"}}
    expect(response).to redirect_to("/root/grid_schematics/fresh/edit")

    expect { delete "/root/grid_schematics/fresh" }.to change(GridSchematic, :count).by(-1)
    expect(response).to redirect_to("/root/grid_schematics")
  end
end
