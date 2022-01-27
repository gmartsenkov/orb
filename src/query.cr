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

      def values
        [value]
      end
    end

    @select = Array(String).new
    @distinct = Array(String).new
    @group_by = Array(String).new
    @from : String?
    @where = Array(Where | Fragment).new
    @limit : Int32?
    @offset : Int32?

    def distinct(*columns)
      @distinct = columns.to_a.map(&.to_s)
      self
    end

    def select(*columns)
      @select = columns.to_a.map(&.to_s)
      self
    end

    def group_by(*columns)
      @group_by = columns.to_a.map(&.to_s)
      self
    end

    def from(table)
      @from = table.to_s
      self
    end

    def limit(value)
      @limit = value
      self
    end

    def offset(value)
      @offset = value
      self
    end

    def where(fragment : Fragment)
      @where.push(fragment)
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
      query = String.new

      if @select.any? && @distinct.none?
        cols = @select.join(", ")
        query += "SELECT #{cols} "
      end

      if @distinct.any?
        cols = @distinct.join(", ")
        query += "SELECT DISTINCT #{cols} "
      end

      if @from
        query += "FROM #{@from} "
      end

      if @where.any?
        query += "WHERE "
        query += @where.map_with_index do |clause, i|
          position = i.zero? ? 1 : @where[0..i].flat_map(&.values).size
          clause.to_sql(position)
        end.join(" AND ")

        values.concat(@where.flat_map(&.values))
      end

      if @group_by.any?
        cols = @group_by.join(", ")
        query += " GROUP BY #{cols}"
      end

      if @limit
        query += " LIMIT $#{values.size + 1}"
        values.push(@limit)
      end

      if @offset
        query += " OFFSET $#{values.size + 1}"
        values.push(@offset)
      end

      Result.new(query: query.strip, values: values)
    end
  end
end
