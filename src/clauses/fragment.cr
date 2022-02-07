require "../orb"

module Orb
  class Clauses
    struct Fragment
      property query : String
      property values : Array(Orb::TYPES)

      def initialize(@query, @values = [] of Orb::TYPES)
      end

      def to_sql(position)
        query = @query

        query.gsub("?") do
          new = "$#{position}"
          position += 1
          new
        end
      end
    end
  end
end
