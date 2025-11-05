class CreateRedirects < ActiveRecord::Migration[8.0]
  def change
    create_table :redirects do |t|
      t.string :domain
      t.string :path
      t.string :destination_url

      t.timestamps
    end

    add_index :redirects, [:domain, :path], unique: true
  end
end
