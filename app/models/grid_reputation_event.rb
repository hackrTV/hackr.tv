# == Schema Information
#
# Table name: grid_reputation_events
# Database name: primary
#
#  id            :integer          not null, primary key
#  delta         :integer          not null
#  note          :text
#  reason        :string
#  source_type   :string
#  subject_type  :string           not null
#  value_after   :integer          not null
#  created_at    :datetime         not null
#  grid_hackr_id :integer          not null
#  source_id     :bigint
#  subject_id    :bigint           not null
#
# Indexes
#
#  index_grid_reputation_events_on_grid_hackr_id  (grid_hackr_id)
#  index_rep_events_on_hackr_and_time             (grid_hackr_id,created_at DESC)
#  index_rep_events_on_source                     (source_type,source_id)
#  index_rep_events_on_subject_and_time           (subject_type,subject_id,created_at DESC)
#
# Foreign Keys
#
#  grid_hackr_id  (grid_hackr_id => grid_hackrs.id)
#
class GridReputationEvent < ApplicationRecord
  belongs_to :grid_hackr
  belongs_to :subject, polymorphic: true
  belongs_to :source, polymorphic: true, optional: true

  validates :delta, presence: true, numericality: {only_integer: true}
  validates :value_after, presence: true, numericality: {only_integer: true}

  # Append-only: no updates in app code (enforced by convention — the service
  # layer only inserts, the admin UI is read-only). Destroy is allowed so the
  # hackr `dependent: :destroy` cascade can succeed when a hackr is deleted.
  def readonly?
    persisted? && !@allow_destroy && !destroyed?
  end

  def destroy
    @allow_destroy = true
    super
  ensure
    @allow_destroy = false
  end

  scope :recent, -> { order(created_at: :desc) }
  scope :for_hackr, ->(hackr) { where(grid_hackr: hackr) }
  scope :for_subject, ->(subject) { where(subject_type: subject.class.name, subject_id: subject.id) }
end
