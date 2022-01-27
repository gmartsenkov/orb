require "../query"

module Orb
  class Query
    struct Insert
      property table : String | Symbol
      property columns : Array(String)
      property values : Array(Orb::TYPES)

      def initialize(@table, @columns, @values)
      end

      def to_sql(position)
        columns = @columns.join(", ")
        "INSERT INTO #{@table}(#{columns}) VALUES (#{values_string(position, @values.size)})"
      end

      private def values_string(position, value_size)
        (0...value_size)
          .map { |i| "$#{i + position}" }
          .join(", ")
      end
    end
  end
end
