class CreateSentEmails < ActiveRecord::Migration[8.1]
  def change
    create_table :sent_emails do |t|
      t.string :to, null: false
      t.string :from, null: false
      t.string :subject, null: false
      t.text :text_body
      t.text :html_body
      t.string :mailer_class, null: false
      t.string :mailer_action, null: false
      t.references :emailable, polymorphic: true, null: true

      t.timestamps
    end

    add_index :sent_emails, :created_at
  end
end
