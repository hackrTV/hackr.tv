class Pulse < ApplicationRecord
  include ProfanityFilterable

  belongs_to :grid_hackr
  belongs_to :parent_pulse, class_name: "Pulse", optional: true
  belongs_to :thread_root, class_name: "Pulse", optional: true
  has_many :echoes, dependent: :destroy
  has_many :splices, class_name: "Pulse", foreign_key: :parent_pulse_id, dependent: :destroy
  has_many :hackrs_who_echoed, through: :echoes, source: :grid_hackr

  validates :content, presence: true, length: {maximum: 256}
  validates :pulsed_at, presence: true
  validate :cannot_splice_signal_dropped_pulse
  filter_profanity :content

  before_validation :set_pulsed_at, on: :create
  before_save :set_thread_root

  scope :active, -> { where(signal_dropped: false) }
  scope :dropped, -> { where(signal_dropped: true) }
  scope :timeline, -> { order(pulsed_at: :desc) }
  scope :roots, -> { where(parent_pulse_id: nil) }
  scope :splices_for, ->(pulse_id) { where(parent_pulse_id: pulse_id).order(pulsed_at: :asc) }

  def is_splice?
    parent_pulse_id.present?
  end

  def is_echo_by?(hackr)
    return false unless hackr
    echoes.exists?(grid_hackr_id: hackr.id)
  end

  def signal_drop!
    update(signal_dropped: true, signal_dropped_at: Time.current)
  end

  def restore!
    update(signal_dropped: false, signal_dropped_at: nil)
  end

  def thread_pulses
    # If this pulse is the root (no thread_root_id), find all pulses that point to it
    if thread_root_id.nil?
      Pulse.where(thread_root_id: id).or(Pulse.where(id: id)).timeline
    else
      # If this pulse is part of a thread, find the root and all siblings
      Pulse.where(thread_root_id: thread_root_id).or(Pulse.where(id: thread_root_id)).timeline
    end
  end

  private

  def set_pulsed_at
    self.pulsed_at ||= Time.current
  end

  def set_thread_root
    if parent_pulse_id.present? && thread_root_id.nil?
      # If we have a parent, inherit its thread_root or use the parent as root
      self.thread_root_id = parent_pulse.thread_root_id || parent_pulse.id
    end
  end

  def cannot_splice_signal_dropped_pulse
    if parent_pulse_id.present? && parent_pulse&.signal_dropped?
      errors.add(:parent_pulse_id, "cannot splice a signal-dropped pulse")
    end
  end
end
