class Migration~~~VERSION~~~
  def migrate(db_path)
    db = SQLite3::Database.open(db_path)

    db.transaction

    # TODO: Put migration code here.

    # Do not change this query.
    db.execute("PRAGMA user_version = ~~~VERSION~~~;")

    db.commit
  rescue SQLite3::Exception => ex
    db.rollback
    puts ""
    puts "SQLite3::Exception occurred"
    puts ex.message
    puts ""
    puts ex
    puts ""
  ensure
    db.close if db
  end
end
