require "../orb"

module Orb
  class Query
    struct Distinct
      property columns : Array(String)

      def initialize(@columns)
      end

      def values
        [] of Orb::TYPES
      end

      def to_sql(_position)
        "SELECT DISTINCT #{@columns.join(", ")}"
      end
    end
  end
end
