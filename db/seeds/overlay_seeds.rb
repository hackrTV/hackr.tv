# Overlay seed data - Default scenes, tickers, and lower thirds for OBS overlays

puts "\n=== Seeding Overlay data ==="

# Clear existing overlay data for clean re-seeding
puts "Clearing existing overlay data..."
OverlaySceneElement.destroy_all
OverlayScene.destroy_all
OverlayElement.destroy_all
OverlayTicker.destroy_all
OverlayLowerThird.destroy_all
OverlayAlert.destroy_all
OverlayNowPlaying.destroy_all

# Create overlay elements (reusable building blocks)
puts "Creating overlay elements..."

now_playing_element = OverlayElement.create!(
  name: "Now Playing",
  slug: "now-playing",
  element_type: "now_playing"
)

pulsewire_element = OverlayElement.create!(
  name: "PulseWire Feed",
  slug: "pulsewire-feed",
  element_type: "pulsewire_feed"
)

alerts_element = OverlayElement.create!(
  name: "Alert Box",
  slug: "alert-box",
  element_type: "alert"
)

OverlayElement.create!(
  name: "Lower Third",
  slug: "lower-third",
  element_type: "lower_third"
)

OverlayElement.create!(
  name: "Top Ticker",
  slug: "ticker-top",
  element_type: "ticker_top"
)

ticker_bottom_element = OverlayElement.create!(
  name: "Bottom Ticker",
  slug: "ticker-bottom",
  element_type: "ticker_bottom"
)

puts "Created #{OverlayElement.count} overlay elements"

# Create default tickers (one per position: top, bottom)
puts "Creating tickers..."

OverlayTicker.create!(
  name: "Top Ticker",
  slug: "top",
  content: "SYSTEM NOTIFICATION: All transmissions monitored by PRISM // Maintain signal discipline // Trust no one",
  direction: "left",
  speed: 80,
  active: true
)

OverlayTicker.create!(
  name: "Bottom Ticker",
  slug: "bottom",
  content: "THE.CYBERPUL.SE // LIVE FROM THE PULSE GRID // TUNE IN TO hackr.fm FOR THE FUTURE SOUND // PULSEWIRE: THE SIGNAL NEVER SLEEPS",
  direction: "left",
  speed: 100,
  active: true
)

puts "Created #{OverlayTicker.count} tickers"

# Create default lower thirds
puts "Creating lower thirds..."

OverlayLowerThird.create!(
  name: "XERAEN",
  slug: "xeraen",
  primary_text: "XERAEN",
  secondary_text: "Musician // Producer // The Pulse Grid Architect",
  active: true
)

OverlayLowerThird.create!(
  name: "hackr.fm",
  slug: "hackr-fm",
  primary_text: "hackr.fm",
  secondary_text: "Future Sound for Future People",
  active: true
)

OverlayLowerThird.create!(
  name: "Guest Speaker",
  slug: "guest",
  primary_text: "Guest",
  secondary_text: "Guest appearance on THE.CYBERPUL.SE",
  active: true
)

puts "Created #{OverlayLowerThird.count} lower thirds"

# Create fullscreen scenes
puts "Creating scenes..."

OverlayScene.create!(
  name: "Stream Starting",
  slug: "intro",
  scene_type: "fullscreen",
  width: 1920,
  height: 1080
)

OverlayScene.create!(
  name: "Be Right Back",
  slug: "brb",
  scene_type: "fullscreen",
  width: 1920,
  height: 1080
)

OverlayScene.create!(
  name: "Stream Ending",
  slug: "ending",
  scene_type: "fullscreen",
  width: 1920,
  height: 1080
)

# Create a composition scene (main streaming layout)
main_composition = OverlayScene.create!(
  name: "Main Streaming Layout",
  slug: "main-layout",
  scene_type: "composition",
  width: 1920,
  height: 1080
)

puts "Created #{OverlayScene.count} scenes"

# Add elements to the main composition
puts "Composing main layout..."

# Now Playing in bottom left corner
OverlaySceneElement.create!(
  overlay_scene: main_composition,
  overlay_element: now_playing_element,
  x: 20,
  y: 940,
  width: 400,
  height: 120,
  z_index: 10
)

# PulseWire feed on the right side
OverlaySceneElement.create!(
  overlay_scene: main_composition,
  overlay_element: pulsewire_element,
  x: 1500,
  y: 100,
  width: 400,
  height: 500,
  z_index: 5
)

# Alerts centered at top
OverlaySceneElement.create!(
  overlay_scene: main_composition,
  overlay_element: alerts_element,
  x: 710,
  y: 100,
  width: 500,
  height: 200,
  z_index: 20
)

# Bottom ticker
OverlaySceneElement.create!(
  overlay_scene: main_composition,
  overlay_element: ticker_bottom_element,
  x: 0,
  y: 1040,
  width: 1920,
  height: 40,
  z_index: 15
)

puts "Added #{OverlaySceneElement.count} elements to compositions"

# Display summary
puts "\n=== Overlay Seed Summary ==="
puts "Elements: #{OverlayElement.count}"
puts "Scenes: #{OverlayScene.count}"
puts "  - Fullscreen: #{OverlayScene.where(scene_type: "fullscreen").count}"
puts "  - Composition: #{OverlayScene.where(scene_type: "composition").count}"
puts "Tickers: #{OverlayTicker.count}"
puts "Lower Thirds: #{OverlayLowerThird.count}"
puts "Scene Elements: #{OverlaySceneElement.count}"
puts "\n=== Overlay seeding complete! ==="
