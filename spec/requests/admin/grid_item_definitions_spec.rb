require "rails_helper"

# /root/grid_item_definitions — the item catalog ledger and the item
# record as console screens (console-ui-for-all-admin Phase 4,
# 2026-11-01).
RSpec.describe "Admin grid item definitions", type: :request do
  let!(:admin) { create(:grid_hackr, :admin, password: "hackthegrid") }
  let!(:operative) { create(:grid_hackr, password: "hackthegrid") }

  def log_in!(hackr)
    post "/grid/login", params: {hackr_alias: hackr.hackr_alias, password: "hackthegrid"}
  end

  it "denies non-admins" do
    log_in!(operative)
    get "/root/grid_item_definitions"

    expect(response).not_to have_http_status(:ok)
  end

  it "lists the definitions as numbered ledger rows with the TYPE row, the filter, destinations and the prompt" do
    create(:grid_item_definition, name: "Pulse Cutter", slug: "pulse-cutter", item_type: "tool", rarity: "rare", value: 1200)
    create(:grid_item_definition, :consumable, name: "Stim Pack", slug: "stim-pack")
    log_in!(admin)

    get "/root/grid_item_definitions"

    expect(response).to have_http_status(:ok)
    body = response.body
    expect(body).to be_console_clean
    expect(body).to include("2 definitions", "2 types")
    expect(body).to include("[01]", "[02]", 'data-command="02"', 'id="ledger-filter"')
    expect(body).to include('data-search="pulse cutter pulse-cutter tool rare"', "1,200")
    expect(body).to include("/root/grid_item_definitions/pulse-cutter/edit", "/root/grid_item_definitions/pulse-cutter/history")
    expect(body).to include("/root/grid_item_definitions?item_type=rig_component", "[SCHEMATICS]", "[SHOPS]")
    expect(body).not_to include("[ITEMS]")
    expect(body).to include("type an item number")
  end

  it "narrows to a listed TYPE and reads an unknown one unfiltered" do
    create(:grid_item_definition, name: "Pulse Cutter", item_type: "tool")
    create(:grid_item_definition, :consumable, name: "Stim Pack")
    log_in!(admin)

    get "/root/grid_item_definitions", params: {item_type: "consumable"}
    expect(response.body).to include("Stim Pack", "CONSUMABLE")
    expect(response.body).not_to include("Pulse Cutter")
    expect(response.body).to include(%(class="rc-btn rc-btn--on" aria-current="page" href="/root/grid_item_definitions?item_type=consumable"))

    get "/root/grid_item_definitions", params: {item_type: "bogus"}
    expect(response.body).to include("Stim Pack", "Pulse Cutter")
    expect(response.body).to include(%(class="rc-btn rc-btn--on" aria-current="page" href="/root/grid_item_definitions"))
  end

  it "renders the record with the fields, properties, yield rows and the hooks the yield script targets" do
    definition = create(:grid_item_definition, :component, name: "Flux GPU", slug: "flux-gpu", max_stack: 5)
    output = create(:grid_item_definition, name: "Copper Wire", rarity: "common")
    create(:grid_salvage_yield, source_definition: definition, output_definition: output, quantity: 3, position: 1)
    log_in!(admin)

    get "/root/grid_item_definitions/flux-gpu/edit"

    body = response.body
    expect(response).to have_http_status(:ok)
    expect(body).to be_console_clean
    expect(body).to include('value="Flux GPU"', 'action="/root/grid_item_definitions/flux-gpu"', 'name="grid_item_definition[item_type]"',
      'name="grid_item_definition[rarity]"', 'name="grid_item_definition[max_stack]"', 'name="grid_item_definition[properties_json]"')
    expect(body).to include("IN USE", "0 live items", "0 listings", "0 salvage yields")
    expect(body).to include("&quot;slot&quot;: &quot;gpu&quot;")
    expect(body).to include("// SALVAGE YIELDS //", 'id="salvage-yields-table"', 'id="add-yield-btn"', 'id="yield-row-template"', "yield-destroy-btn")
    expect(body).to include('name="grid_item_definition[salvage_yields_attributes][0][quantity]"', 'value="3"', 'class="destroy-flag"', 'data-persisted="true"')
    expect(body).to include("salvage_yields_attributes][__INDEX__][output_definition_id]", "Copper Wire [COMMON]")
    expect(body).to include('form="delete-item"', 'id="delete-item"', "[HISTORY]")
    script = body[/<script nonce="[^"]*">\s*\(function\(\) \{\s*var yieldRowIndex.*?<\/script>/m]
    expect(script).to include("closest('.rc-row')", "row.hidden = true")
    expect(script).not_to include("tui-", "style.")
  end

  it "saves every field, the properties JSON and a new yield, and stays on the record" do
    definition = create(:grid_item_definition, name: "Old", slug: "old-item")
    output = create(:grid_item_definition, name: "Scrap Metal")
    log_in!(admin)

    patch "/root/grid_item_definitions/old-item", params: {grid_item_definition: {
      name: "Flux GPU", slug: "flux-gpu", description: "Fast.", item_type: "rig_component", rarity: "rare", value: "900", max_stack: "2",
      properties_json: %({"slot": "gpu", "rate_multiplier": 1.5}),
      salvage_yields_attributes: {"1000" => {position: "0", output_definition_id: output.id.to_s, quantity: "4"}}
    }}

    expect(response).to redirect_to("/root/grid_item_definitions/flux-gpu/edit")
    follow_redirect!
    expect(response.body).to include("[OK]", ERB::Util.html_escape("Definition 'Flux GPU' updated."))
    expect(definition.reload).to have_attributes(name: "Flux GPU", slug: "flux-gpu", description: "Fast.", item_type: "rig_component",
      rarity: "rare", value: 900, max_stack: 2, properties: {"slot" => "gpu", "rate_multiplier" => 1.5})
    expect(definition.salvage_yields.map { |y| [y.output_definition_id, y.quantity] }).to eq([[output.id, 4]])
  end

  it "removes a saved yield through its _destroy flag" do
    definition = create(:grid_item_definition, slug: "flux-gpu")
    salvage = create(:grid_salvage_yield, source_definition: definition)
    log_in!(admin)

    patch "/root/grid_item_definitions/flux-gpu", params: {grid_item_definition: {
      properties_json: "{}", salvage_yields_attributes: {"0" => {id: salvage.id.to_s, _destroy: "1"}}
    }}

    expect(response).to redirect_to("/root/grid_item_definitions/flux-gpu/edit")
    expect(GridSalvageYield.exists?(salvage.id)).to be(false)
  end

  it "rejects bad JSON with a 422, the error on PROPERTIES and the JSON as typed" do
    create(:grid_item_definition, name: "Flux GPU", slug: "flux-gpu")
    log_in!(admin)

    patch "/root/grid_item_definitions/flux-gpu", params: {grid_item_definition: {name: "Flux GPU", properties_json: %({"slot": })}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to be_console_clean
    expect(response.body).to include("[ERR]", "rc-err", "is not valid JSON", "{&quot;slot&quot;: }")
    expect(response.body).to include('action="/root/grid_item_definitions/flux-gpu"')
  end

  it "rejects a blank name with a 422, posting back to the slug on record, a removed yield still flagged and hidden" do
    definition = create(:grid_item_definition, name: "Flux GPU", slug: "flux-gpu")
    salvage = create(:grid_salvage_yield, source_definition: definition)
    log_in!(admin)

    patch "/root/grid_item_definitions/flux-gpu", params: {grid_item_definition: {name: "", slug: "renamed", properties_json: "{}",
                                                                                  salvage_yields_attributes: {"0" => {id: salvage.id.to_s, _destroy: "1"}}}}

    expect(response).to have_http_status(:unprocessable_entity)
    expect(response.body).to include("[ERR]", "rc-err", 'action="/root/grid_item_definitions/flux-gpu"', "Flux GPU")
    expect(response.body).to match(/<div class="rc-row" hidden="hidden">\s*<span><input[^>]*name="grid_item_definition\[salvage_yields_attributes\]\[0\]\[position\]"/)
    expect(response.body[/<input(?=[^>]*name="grid_item_definition\[salvage_yields_attributes\]\[0\]\[_destroy\]")[^>]*>/]).to include('value="1"')
    expect(GridSalvageYield.exists?(salvage.id)).to be(true)
  end

  it "creates a definition and opens its record; deletes one through the hidden form" do
    log_in!(admin)

    get "/root/grid_item_definitions/new"
    expect(response.body).to be_console_clean
    expect(response.body).to include("NEW ITEM", 'id="yield-row-template"')

    post "/root/grid_item_definitions", params: {grid_item_definition: {name: "Fresh", slug: "fresh", item_type: "data", rarity: "common", value: "0", properties_json: "{}"}}
    expect(response).to redirect_to("/root/grid_item_definitions/fresh/edit")

    expect { delete "/root/grid_item_definitions/fresh" }.to change(GridItemDefinition, :count).by(-1)
    expect(response).to redirect_to("/root/grid_item_definitions")
  end
end
