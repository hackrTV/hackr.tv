require "sqlite3"

namespace :db do
  namespace :data do
    desc "Creates missing redirects, skips any which already exist."
    task :redirects do
      # TODO: Created migration for redirects table and then make this task funcitonal.
    end
  end
end
