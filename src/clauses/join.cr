require "../query"
require "../orb"
require "./fragment"

module Orb
  class Clauses
    struct Join
      property table : String | Symbol
      property direction : Query::Joins
      property columns : Tuple(String | Symbol, String | Symbol)

      def initialize(@table, @columns, @direction)
      end

      def to_sql(position)
        "#{direction_string} #{@table} ON #{@columns[0]} = #{columns[1]}"
      end

      def values
        [] of Orb::TYPES
      end

      private def direction_string
        case @direction
        when Query::Joins::Left
          "LEFT JOIN"
        when Query::Joins::Right
          "RIGHT JOIN"
        when Query::Joins::Inner
          "INNER JOIN"
        when Query::Joins::Full
          "FULL JOIN"
        when Query::Joins::Cross
          "CROSS JOIN"
        else
          raise "unknown JOIN"
        end
      end
    end
  end
end
