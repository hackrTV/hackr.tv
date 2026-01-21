class CreateUplinkTables < ActiveRecord::Migration[8.0]
  def change
    # Chat channels (e.g., #ambient, #live)
    create_table :chat_channels do |t|
      t.string :slug, null: false
      t.string :name, null: false
      t.text :description
      t.boolean :is_active, default: true, null: false
      t.boolean :requires_livestream, default: false, null: false
      t.integer :slow_mode_seconds, default: 0, null: false
      t.string :minimum_role, default: "operative", null: false

      t.timestamps
    end

    add_index :chat_channels, :slug, unique: true
    add_index :chat_channels, :is_active

    # Chat messages (packets)
    create_table :chat_messages do |t|
      t.references :chat_channel, null: false, foreign_key: true
      t.references :grid_hackr, null: false, foreign_key: true
      t.references :hackr_stream, null: true, foreign_key: true
      t.text :content, null: false
      t.boolean :dropped, default: false, null: false
      t.datetime :dropped_at

      t.timestamps
    end

    add_index :chat_messages, [:chat_channel_id, :created_at]
    add_index :chat_messages, :dropped

    # Moderation logs (audit trail)
    create_table :moderation_logs do |t|
      t.references :actor, null: false, foreign_key: {to_table: :grid_hackrs}
      t.references :target, null: true, foreign_key: {to_table: :grid_hackrs}
      t.references :chat_message, null: true, foreign_key: true
      t.string :action, null: false
      t.text :reason
      t.integer :duration_minutes

      t.timestamps
    end

    add_index :moderation_logs, :action
    add_index :moderation_logs, :created_at

    # User punishments (squelch, blackout)
    create_table :user_punishments do |t|
      t.references :grid_hackr, null: false, foreign_key: true
      t.string :punishment_type, null: false
      t.datetime :expires_at
      t.text :reason
      t.references :issued_by, null: false, foreign_key: {to_table: :grid_hackrs}

      t.timestamps
    end

    add_index :user_punishments, [:grid_hackr_id, :punishment_type]
    add_index :user_punishments, :expires_at
  end
end
