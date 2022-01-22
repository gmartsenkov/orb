require "db"

module Orb
  abstract class Relation
    include DB::Serializable
    @@column_names = Array(String).new

    macro table(name)
      include DB::Serializable

      def self.table_name
        {{name}}
      end
    end

    macro attribute(name, type)
      @@column_names.push({{name}}.to_s)
      property {{name.id}} : {{type}}
    end

    def self.column_names
      @@column_names
    end
  end
end
