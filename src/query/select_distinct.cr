require "../orb"

module Orb
  class Query
    struct SelectDistinct
      property columns : Array(String)
      property distinct_columns : Array(String)

      def initialize(@columns, @distinct_columns)
      end

      def to_sql(_position)
        "SELECT DISTINCT ON(#{@distinct_columns.join(", ")}) #{@columns.join(", ")}"
      end

      def values
        [] of Orb::TYPES
      end
    end
  end
end
