# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).
#
# DATA ARCHITECTURE:
# All seed data is managed via YAML files in the data/ directory structure:
#   data/catalog/    - Artists, albums, tracks
#   data/system/     - Hackrs, channels, radio stations, redirects, zone playlists
#   data/world/      - Factions, zones, rooms, exits, mobs, items
#   data/content/    - Codex entries, hackr logs, wire (pulses/echoes)
#   data/vidz.yml    - HackrStream VOD/stream records
#   data/playlists/  - Key playlists with radio station links
#   data/overlays/   - Elements, scenes, scene elements, tickers, lower thirds
#   (derived)        - Livestream archive playlist (built from tracks with audio)
#
# To reload data:
#   rails data:load         # Full load of all data
#   rails data:reset        # Reset seed content only (preserves user data)
#   rails data:catalog      # Reload only catalog data
#   rails data:content      # Reload only content data
#   etc.
#
# See lib/tasks/data.rake for all available tasks.

# Delegate to the unified data:load rake task
Rake::Task["data:load"].invoke
