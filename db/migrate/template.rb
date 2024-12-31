class Migration~~~VERSION~~~
  def migrate(db_path)
    db = SQLite3::Database.open(db_path)

    # NOTE: We want `.first.first` as the query result is `[[0]]`
    database_version = db.execute("PRAGMA user_version;").first.first

    if "~~~VERSION~~~".to_i <= database_version
      raise(
        " >> Database already includes version #{"~~~VERSION~~~".to_i}, but " \
        "we ran the migrate method on an instance of Migration~~~VERSION~~~! " \
        "This should not happen! Aborting..."
      )
    end

    db.transaction

    # =========================================================================
    # Do not change above this line.
    # =========================================================================

    # BEGIN migration code.
    # END migration code.

    # =========================================================================
    # Do not change below this line.
    # =========================================================================

    db.execute("PRAGMA user_version = #{"~~~VERSION~~~".to_i};")

    db.commit
  rescue => ex
    db.rollback if db && db.transaction_active?
    puts ""
    puts "Exception occurred"
    puts ex.message
    puts ""
    puts ex.inspect
    puts ""
  ensure
    db.close if db
  end
end
