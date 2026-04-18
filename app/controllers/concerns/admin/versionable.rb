module Admin::Versionable
  extend ActiveSupport::Concern

  SKIP_KEYS = %w[id created_at updated_at].freeze

  class_methods do
    def versionable(model_class, find_by: :id, children: [])
      define_method(:history) do
        @record = if find_by == :slug
          model_class.find_by!(slug: params[:id])
        else
          model_class.find(params[:id])
        end

        @model_name = model_class.model_name.human
        @model_class = model_class
        @back_path = url_for(action: :index)
        @entries = build_timeline(@record, children)

        render "admin/shared/version_history"
      end
    end
  end

  private

  # Returns an array of {version:, source:, changes:} sorted desc by time.
  def build_timeline(record, child_assocs)
    entries = []

    # Parent versions
    record.versions.each do |version|
      entries << {
        version: version,
        source: record.class.model_name.human,
        changes: compute_diff(record, version)
      }
    end

    # Child association versions
    child_assocs.each do |assoc_name|
      reflection = record.class.reflect_on_association(assoc_name)
      next unless reflection

      child_class = reflection.klass
      # All child record IDs (current + historically deleted)
      child_ids = child_class.unscoped.where(
        reflection.foreign_key => record.id
      ).pluck(:id)

      next if child_ids.empty?

      child_versions = PaperTrail::Version.where(
        item_type: child_class.name,
        item_id: child_ids
      )

      parent_fk = reflection.foreign_key.to_s

      child_versions.each do |version|
        child_label = child_display_label(child_class, version)

        entries << {
          version: version,
          source: child_label,
          changes: compute_child_diff(child_class, version, parent_fk)
        }
      end
    end

    entries.sort_by { |e| e[:version].created_at }.reverse
  end

  def child_display_label(child_class, version)
    human = child_class.model_name.human
    # Try to get a meaningful identifier from the stored object
    attrs = safe_load_object(version)
    if attrs
      name = attrs["name"] || attrs["label"] || attrs["title"] || attrs["slug"]
      return "#{human}: #{name}" if name.present?

      # For positional children like objectives/rewards
      pos = attrs["position"]
      return "#{human} ##{pos}" if pos.present?
    end

    # Fallback: try loading the live record
    live = child_class.find_by(id: version.item_id)
    if live
      name = if live.respond_to?(:label)
        live.label
      elsif live.respond_to?(:name)
        live.name
      end
      return "#{human}: #{name}" if name.present?
    end

    "#{human} ##{version.item_id}"
  end

  def compute_child_diff(child_class, version, parent_fk)
    # Only skip the FK pointing back to the parent — other FKs are meaningful
    skip = SKIP_KEYS + [parent_fk]

    case version.event
    when "create"
      after = safe_load_object(version.next) || find_live_attrs(child_class, version.item_id)
      return [] if after.blank?

      after.except(*skip).filter_map do |key, value|
        next if value.nil? || value == "" || value == 0 || value == false
        {key: key, from: nil, to: resolve_display(child_class, key, value)}
      end

    when "update"
      before = safe_load_object(version)
      return [] if before.blank?

      after = safe_load_object(version.next) || find_live_attrs(child_class, version.item_id)
      return [] if after.blank?

      before.except(*skip).filter_map do |key, old_val|
        new_val = after[key]
        next if normalize(old_val) == normalize(new_val)
        {
          key: key,
          from: resolve_display(child_class, key, old_val),
          to: resolve_display(child_class, key, new_val)
        }
      end

    when "destroy"
      before = safe_load_object(version)
      return [] if before.blank?

      before.except(*skip).filter_map do |key, value|
        next if value.nil? || value == "" || value == 0 || value == false
        {key: key, from: resolve_display(child_class, key, value), to: nil}
      end

    else
      []
    end
  end

  def compute_diff(record, version)
    case version.event
    when "create"
      after = safe_load_object(version.next) || record.attributes
      return [] if after.blank?

      after.except(*SKIP_KEYS).filter_map do |key, value|
        next if value.nil? || value == "" || value == 0 || value == false
        {key: key, from: nil, to: resolve_display(record.class, key, value)}
      end

    when "update"
      before = safe_load_object(version)
      return [] if before.blank?

      after = safe_load_object(version.next) || record.attributes
      return [] if after.blank?

      before.except(*SKIP_KEYS).filter_map do |key, old_val|
        new_val = after[key]
        next if normalize(old_val) == normalize(new_val)
        {
          key: key,
          from: resolve_display(record.class, key, old_val),
          to: resolve_display(record.class, key, new_val)
        }
      end

    when "destroy"
      before = safe_load_object(version)
      return [] if before.blank?

      before.except(*SKIP_KEYS).filter_map do |key, value|
        next if value.nil? || value == "" || value == 0 || value == false
        {key: key, from: resolve_display(record.class, key, value), to: nil}
      end

    else
      []
    end
  end

  def safe_load_object(version)
    return nil if version.blank? || version.object.blank?
    PaperTrail.serializer.load(version.object)
  rescue
    nil
  end

  def find_live_attrs(klass, id)
    klass.find_by(id: id)&.attributes
  end

  def normalize(value)
    case value
    when Hash then value.to_h.transform_keys(&:to_s)
    when Time, DateTime, ActiveSupport::TimeWithZone then value.to_f.round(3)
    else value
    end
  end

  def resolve_display(model_class, key, value)
    return value unless key.end_with?("_id") && value.present?

    assoc_name = key.delete_suffix("_id")
    reflection = model_class.reflect_on_association(assoc_name.to_sym)
    return value unless reflection

    related = reflection.klass.find_by(id: value)
    return "#{value} (deleted)" unless related

    label = if related.respond_to?(:hackr_alias)
      related.hackr_alias
    elsif related.respond_to?(:name)
      related.name
    elsif related.respond_to?(:title)
      related.title
    elsif related.respond_to?(:slug)
      related.slug
    else
      "##{related.id}"
    end

    "#{label} (##{value})"
  end
end
