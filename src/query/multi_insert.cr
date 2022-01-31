require "../query"

module Orb
  class Query
    struct MultiInsert
      property table : String | Symbol
      property multi_values : Array(Hash(String | Symbol, Orb::TYPES))

      def initialize(@table, @multi_values)
      end

      def to_sql(position)
        columns = @multi_values.flat_map(&.keys).uniq.join(", ")
        "INSERT INTO #{@table}(#{columns}) VALUES #{values_string(position)}"
      end

      def values
        @multi_values.map(&.values).flatten
      end

      private def values_string(position)
        multi_values.map_with_index do |values, i1|
          vals = values.map_with_index do |_, i2|
            "$#{(i1 * values.size) + i2 + position}"
          end.join(", ")

          "(#{vals})"
        end.join(", ")
      end
    end
  end
end
