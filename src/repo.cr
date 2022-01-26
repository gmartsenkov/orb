require "db"

module Orb
  class Repo
    @db : DB::Database | DB::Connection

    def initialize(@db)
    end

    def all(relation)
      relation.from_rs(@db.query("SELECT * FROM #{relation.table_name}"))
    end
  end
end
