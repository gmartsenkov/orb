require "../orb"
require "./*"

module Orb
  class Clauses
    struct From
      property table : String

      getter values = [] of Orb::TYPES

      def initialize(@table)
      end

      def to_sql(_position)
        "FROM #{@table}"
      end
    end
  end
end
