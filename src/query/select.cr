require "../orb"

module Orb
  class Query
    struct Select
      property columns : Array(String)

      getter values = [] of Orb::TYPES

      def initialize(@columns)
      end

      def to_sql(_position)
        "SELECT #{@columns.join(", ")}"
      end
    end
  end
end
