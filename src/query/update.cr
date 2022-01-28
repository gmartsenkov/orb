require "../query"

module Orb
  class Query
    struct Update
      property table : String | Symbol
      property update_values : Hash(String | Symbol, Orb::TYPES)

      def initialize(@table, @update_values)
      end

      def to_sql(position)
        "UPDATE INTO #{@table} SET #{fields(position)}"
      end

      def values
        @update_values.values
      end

      private def fields(position)
        @update_values.keys.map_with_index { |key, i| "#{key} = $#{position + i}" }.join(", ")
      end
    end
  end
end
