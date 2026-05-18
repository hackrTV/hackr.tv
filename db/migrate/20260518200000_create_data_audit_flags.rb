# frozen_string_literal: true

class CreateDataAuditFlags < ActiveRecord::Migration[8.0]
  def change
    create_table :data_audit_flags do |t|
      t.string :fingerprint, null: false
      t.string :check_name, null: false
      t.string :title, null: false
      t.string :severity, null: false, default: "warning"
      t.string :domain, null: false
      t.string :subject_type
      t.integer :subject_id
      t.string :status, null: false, default: "open"
      t.datetime :snooze_until
      t.datetime :first_flagged_at, null: false
      t.datetime :last_seen_at, null: false

      t.timestamps
    end

    add_index :data_audit_flags, :fingerprint, unique: true
    add_index :data_audit_flags, [:status, :severity]
    add_index :data_audit_flags, :check_name
    add_index :data_audit_flags, :domain
    add_index :data_audit_flags, [:subject_type, :subject_id]
  end
end
