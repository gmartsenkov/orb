require "db"
require "./orb"
require "./query/*"

module Orb
  class Query
    struct Where
      property column : String
      property operator : String
      property value : Orb::TYPES

      def initialize(@column, @operator, @value)
      end

      def to_sql(position)
        "#{@column} #{@operator} $#{position}"
      end
    end

    @where = Array(Where).new

    def where(column, value)
      @where.push(Where.new(column.to_s, "=", value))
      self
    end

    def where(**conditions)
      @where.concat(conditions.map { |key, value| Where.new(key.to_s, "=", value) })
      self
    end

    def to_result
      query = @where.map_with_index { |clause, i| clause.to_sql(i + 1) }.join(" AND ")

      Result.new(query: query, values: @where.map(&.value))
    end
  end
end
