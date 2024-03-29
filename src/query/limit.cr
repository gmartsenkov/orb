require "../orb"

module Orb
  class Query
    struct Limit
      property limit : Int32

      def initialize(@limit)
      end

      def to_sql(position)
        "LIMIT $#{position}"
      end

      def values
        [@limit]
      end
    end
  end
end
