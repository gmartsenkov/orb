require "../orb"

module Orb
  class Clauses
    struct GroupBy
      property columns : Array(String)

      getter values = [] of Orb::TYPES

      def initialize(@columns)
      end

      def to_sql(_position)
        "GROUP BY #{@columns.join(", ")}"
      end
    end
  end
end
