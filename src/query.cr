require "db"
require "./orb"
require "db"
require "./query/*"

module Orb
  class Query
    enum LogicalOperator
      And
      Or
    end

    enum Joins
      Left
      Right
      Inner
      Full
      Cross
    end

    alias Clauses = Select | Distinct | Join | From | GroupBy | Where |
                    Limit | Offset | Insert | Update | MultiInsert |
                    SelectDistinct | OrderBy

    @clauses = Array(Clauses).new
    @map_to : Orb::Relation.class | Nil

    CLAUSE_PRIORITY = {
      MultiInsert    => 1,
      Insert         => 1,
      Update         => 1,
      Select         => 1,
      Distinct       => 1,
      SelectDistinct => 1,
      From           => 2,
      OrderBy        => 3,
      Join           => 4,
      Where          => 5,
      GroupBy        => 6,
      Limit          => 7,
      Offset         => 8,
    }

    def map_to(klass)
      @map_to = klass
      self
    end

    def to_a
      Orb.query(self, @map_to.not_nil!)
    end

    def count : Int64
      Orb.scalar(self.select(Fragment.new("COUNT(*)")))
    end

    def update(relation : Orb::Relation)
      @clauses.select!(Where)
      @clauses.push(Update.new(relation.class.table_name, relation.to_h))
      self
    end

    def update(table, values)
      @clauses.select!(Where)
      @clauses.push(Update.new(table, transform_hash(values)))
      self
    end

    def multi_insert(table, values)
      new_values = Array(Hash(String | Symbol, Orb::TYPES)).new
      values.to_a.each { |row| new_values << transform_hash(row) }
      @clauses = [] of Clauses
      @clauses.push(MultiInsert.new(table, new_values))
      self
    end

    def multi_insert(relations : Array(Orb::Relation))
      @clauses = [] of Clauses
      @clauses.push(MultiInsert.new(relations.first.not_nil!.class.table_name, relations.map(&.to_h)))
      self
    end

    def insert(table, values)
      @clauses = [] of Clauses
      @clauses.push(Insert.new(table, transform_hash(values)))
      self
    end

    def insert(relation : Orb::Relation)
      @clauses = [] of Clauses
      @clauses.push(Insert.new(relation.class.table_name, relation.to_h))
      self
    end

    def join(table, columns)
      @clauses.push(Join.new(table, columns, Joins::Inner))
      self
    end

    def inner_join(table, columns)
      @clauses.push(Join.new(table, columns, Joins::Inner))
      self
    end

    def right_join(table, columns)
      @clauses.push(Join.new(table, columns, Joins::Right))
      self
    end

    def left_join(table, columns)
      @clauses.push(Join.new(table, columns, Joins::Left))
      self
    end

    def full_join(table, columns)
      @clauses.push(Join.new(table, columns, Joins::Full))
      self
    end

    def cross_join(table, columns)
      @clauses.push(Join.new(table, columns, Joins::Cross))
      self
    end

    def distinct(*columns)
      @clauses.reject!(Distinct)
      @clauses.push(Distinct.new(columns.to_a.map(&.to_s)))
      self
    end

    def select(fragment : Fragment)
      @clauses.reject!(Select)
      @clauses.push(Select.new(fragment: fragment))
      self
    end

    def select(*columns)
      @clauses.reject!(Select)
      @clauses.push(Select.new(columns.to_a.map(&.to_s)))
      self
    end

    def select(klass : Orb::Relation.class)
      @clauses.reject!(Select)
      @clauses.push(Select.new(klass.column_names))
      @clauses.push(From.new(klass.table_name))
      self
    end

    def group_by(*columns)
      @clauses.reject!(GroupBy)
      @clauses.push(GroupBy.new(columns.to_a.map(&.to_s)))
      self
    end

    def from(table)
      @clauses.reject!(From)
      @clauses.push(From.new(table.to_s))
      self
    end

    def order_by(col : String | Symbol)
      @clauses.reject!(OrderBy)
      @clauses.push(
        OrderBy.new([{col.to_s, "ASC"}])
      )
      self
    end

    def order_by(ordering : Array(Tuple(String, String)))
      @clauses.reject!(OrderBy)
      @clauses.push(OrderBy.new(ordering))
      self
    end

    def order_by(order_by : Array(Tuple(String, String)))
      @clauses.reject!(OrderBy)
      @clauses.push(OrderBy.new(order_by))
      self
    end

    def limit(value)
      @clauses.reject!(Limit)
      @clauses.push(Limit.new(value))
      self
    end

    def offset(value)
      @clauses.reject!(Offset)
      @clauses.push(Offset.new(value))
      self
    end

    {% for pair, _ in [{"where", "LogicalOperator::And"}, {"or_where", "LogicalOperator::Or"}] %}
      def {{pair[0].id}}(fragment : Fragment)
        @clauses.push(Where.new(fragment, {{pair[1].id}}))
        self
      end

      def {{pair[0].id}}(column, operator, value)
        if value.is_a?(Array)
          @clauses.push(Where.new(column.to_s, operator.to_s.upcase, value.map(&.as(Orb::TYPES)), {{pair[1].id}}))
        else
          @clauses.push(Where.new(column.to_s, operator.to_s.upcase, value, {{pair[1].id}}))
        end
        self
      end

      def {{pair[0].id}}(column, value)
        if value.is_a?(Array)
          @clauses.push(Where.new(column.to_s, "IN", value.map(&.as(Orb::TYPES)), {{pair[1].id}}))
        else
          @clauses.push(Where.new(column.to_s, "=", value, {{pair[1].id}}))
        end
        self
      end

      def {{pair[0].id}}(**conditions)
        clauses = conditions.to_a.map_with_index do |condition, i|
          operator = i.zero? ? {{pair[1].id}} : LogicalOperator::And
          value = condition[1]
          if value.is_a?(Array)
            Where.new(condition[0].to_s, "IN", value.map(&.as(Orb::TYPES)), operator)
          else
            Where.new(condition[0].to_s, "=", value, operator)
          end
        end

        @clauses.concat(clauses)
        self
      end
    {% end %}

    def to_result
      clauses = CombineClause.new(@clauses).call.sort_by { |c| CLAUSE_PRIORITY[c.class] }
      values = clauses.flat_map(&.values)
      first_where_clause = clauses.find { |clause| clause.is_a?(Where) }

      query = clauses.map_with_index do |clause, i|
        position = clauses[0...i].flat_map(&.values).size + 1

        if clause == first_where_clause
          "WHERE " + clause.to_sql(position)
        elsif clause.is_a?(Where)
          clause.logical_operator + " " + clause.to_sql(position)
        else
          clause.to_sql(position)
        end
      end.join(" ")

      Result.new(query: query.strip, values: values)
    end

    private def transform_hash(hash)
      new_hash = Hash(String | Symbol, Orb::TYPES).new
      hash.each { |key, val| new_hash.put(key, val) { } }
      new_hash
    end
  end
end
