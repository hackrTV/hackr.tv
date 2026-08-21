# Static lore-timeline data (Hotwire migration Phase 1) — replaces
# app/javascript/components/pages/timeline/timelineData.ts. Source of truth
# is data/content/timeline.yml (machine-converted from the TS module).
# Plain module, not ActiveRecord.
module TimelineData
  class << self
    def eras
      data["eras"]
    end

    def era_map
      @era_map ||= eras.index_by { |e| e["key"] }
    end

    def events
      data["events"]
    end

    def events_by_era(key)
      events.select { |e| e["era"] == key }
    end

    def reload!
      @data = nil
      @era_map = nil
    end

    private

    def data
      @data ||= YAML.safe_load_file(Rails.root.join("data/content/timeline.yml")).freeze
    end
  end
end
