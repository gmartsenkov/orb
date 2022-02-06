require "../query"

module Orb
  class Query
    struct Delete
      property table : String | Symbol

      def initialize(@table)
      end

      def to_sql(position)
        "DELETE FROM #{@table}"
      end

      def values
        [] of Orb::TYPES
      end
    end
  end
end
