require "../orb"
require "./fragment"

module Orb
  class Query
    struct Where
      property column : String
      property operator : String
      property value : Orb::TYPES
      property fragment : Fragment?

      getter priority = 3

      def initialize(@fragment)
        @column = ""
        @operator = ""
      end

      def initialize(@column, @operator, @value)
      end

      def to_sql(position)
        return @fragment.not_nil!.to_sql(position) if @fragment

        "#{@column} #{@operator} $#{position}"
      end

      def values
        @fragment ? @fragment.not_nil!.values : [value]
      end
    end
  end
end
