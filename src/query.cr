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
    @limit : Int32?
    @offset : Int32?

    def limit(value)
      @limit = value
      self
    end

    def offset(value)
      @offset = value
      self
    end

    def where(column, operator, value)
      @where.push(Where.new(column.to_s, operator.to_s.upcase, value))
      self
    end

    def where(column, value)
      @where.push(Where.new(column.to_s, "=", value))
      self
    end

    def where(**conditions)
      @where.concat(conditions.map { |key, value| Where.new(key.to_s, "=", value) })
      self
    end

    def to_result
      values = Array(Orb::TYPES).new
      query = @where.map_with_index { |clause, i| clause.to_sql(i + 1) }.join(" AND ")
      values.concat(@where.map(&.value))

      if @limit
        query += " LIMIT $#{values.size + 1}"
        values.push(@limit)
      end

      if @offset
        query += " OFFSET $#{values.size + 1}"
        values.push(@offset)
      end

      Result.new(query: query, values: values)
    end
  end
end
