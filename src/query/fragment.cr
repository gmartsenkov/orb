require "../orb"

module Orb
  class Query
    class Fragment
      property query : String
      property values : Array(Orb::TYPES)

      macro generate(query, values)
        Orb::Query::Fragment.new({{query}}, {{values}} of Orb::TYPES)
      end

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
