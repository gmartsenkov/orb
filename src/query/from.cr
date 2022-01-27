require "../orb"

module Orb
  class Query
    struct From
      property table : String

      getter priority = 2
      getter values = [] of Orb::TYPES

      def initialize(@table)
      end

      def to_sql(_position)
        "FROM #{@table}"
      end
    end
  end
end
