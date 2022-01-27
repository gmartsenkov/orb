require "../query"
require "../orb"
require "./fragment"

module Orb
  class Query
    struct Where
      property column : String
      property operator : String
      property value : Orb::TYPES
      property logical_operator : LogicalOperator
      property fragment : Fragment?

      def initialize(@fragment, @logical_operator = LogicalOperator::And)
        @column = ""
        @operator = ""
      end

      def initialize(@column, @operator, @value, @logical_operator = LogicalOperator::And)
      end

      def to_sql(position)
        return @fragment.not_nil!.to_sql(position) if @fragment

        "#{@column} #{@operator} $#{position}"
      end

      def logical_operator : String
        case @logical_operator
        when LogicalOperator::And
          "AND"
        when LogicalOperator::Or
          "OR"
        else
          raise "Unknown logical operator"
        end
      end

      def values
        @fragment ? @fragment.not_nil!.values : [value]
      end
    end
  end
end
