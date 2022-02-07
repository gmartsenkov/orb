require "../query"
require "../orb"
require "./fragment"

module Orb
  class Clauses
    struct Where
      property column : String
      property operator : String
      property value : Orb::TYPES | Array(Orb::TYPES)
      property logical_operator : Query::LogicalOperator
      property fragment : Fragment?

      def initialize(@fragment, @logical_operator = LogicalOperator::And)
        @column = ""
        @operator = ""
      end

      def initialize(@column, @operator, @value, @logical_operator = LogicalOperator::And)
      end

      def to_sql(position)
        return @fragment.not_nil!.to_sql(position) if @fragment

        "#{@column} #{@operator} #{sql_values(position)}"
      end

      def values
        value = @value
        return value if value.is_a?(Array(Orb::TYPES))

        @fragment ? @fragment.not_nil!.values : [value]
      end

      def logical_operator : String
        case @logical_operator
        when Query::LogicalOperator::And
          "AND"
        when Query::LogicalOperator::Or
          "OR"
        else
          raise "Unknown logical operator"
        end
      end

      def sql_values(position)
        value = @value
        if value.is_a?(Array)
          vals = (position...(value.size + position)).map { |x| "$#{x}" }.join(", ")
          "(#{vals})"
        else
          "$#{position}"
        end
      end
    end
  end
end
