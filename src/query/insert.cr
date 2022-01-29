require "../query"

module Orb
  class Query
    struct Insert
      property table : String | Symbol
      property fields : Hash(String | Symbol, Orb::TYPES)

      def initialize(@table, @fields)
      end

      def to_sql(position)
        "INSERT INTO #{@table}(#{@fields.keys.join(", ")}) VALUES (#{values_string(position)})"
      end

      def values
        @fields.values
      end

      private def values_string(position)
        @fields.keys
          .map_with_index { |_, i| "$#{i + position}" }
          .join(", ")
      end
    end
  end
end
