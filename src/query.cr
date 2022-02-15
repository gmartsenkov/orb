require "./orb"
require "db"
require "./clauses/*"

module Orb
  class Query(R)
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

    alias Clause = Clauses::Select | Clauses::Distinct | Clauses::Join | Clauses::From | Clauses::GroupBy | Clauses::Where |
                   Clauses::Limit | Clauses::Offset | Clauses::Insert | Clauses::Update | Clauses::MultiInsert |
                   Clauses::SelectDistinct | Clauses::OrderBy | Clauses::Delete

    @clauses = Array(Clause).new
    @combines = Array(Symbol).new

    CLAUSE_PRIORITY = {
      Clauses::MultiInsert    => 1,
      Clauses::Insert         => 1,
      Clauses::Delete         => 1,
      Clauses::Update         => 1,
      Clauses::Select         => 1,
      Clauses::Distinct       => 1,
      Clauses::SelectDistinct => 1,
      Clauses::From           => 2,
      Clauses::OrderBy        => 3,
      Clauses::Join           => 4,
      Clauses::Where          => 5,
      Clauses::GroupBy        => 6,
      Clauses::Limit          => 7,
      Clauses::Offset         => 8,
    }

    def to_a
      Orb.query(self, R).tap do |results|
        @combines.each { |assoc| R.combine(results, assoc) }
      end
    end

    def commit
      Orb.exec(self)
    end

    def count : Int64
      Orb.scalar(self.select(Clauses::Fragment.new("COUNT(*)")))
    end

    def combine(*args)
      @combines = args.to_a
      self
    end

    def update(relation : Orb::Relation)
      @clauses.select!(Clauses::Where)
      @clauses.push(Clauses::Update.new(relation.class.table_name, relation.to_h))
      self
    end

    def update(table, values)
      @clauses.select!(Clauses::Where)
      @clauses.push(Clauses::Update.new(table, transform_hash(values)))
      self
    end

    def delete(table)
      @clauses.select!(Clauses::Where)
      @clauses.push(Clauses::Delete.new(table))
      self
    end

    def multi_insert(table, values)
      new_values = Array(Hash(String | Symbol, Orb::TYPES)).new
      values.to_a.each { |row| new_values << transform_hash(row) }
      @clauses = [] of Clause
      @clauses.push(Clauses::MultiInsert.new(table, new_values))
      self
    end

    def multi_insert(relations : Array(Orb::Relation))
      @clauses = [] of Clause
      @clauses.push(Clauses::MultiInsert.new(relations.first.not_nil!.class.table_name, relations.map(&.to_h)))
      self
    end

    def insert(table, values)
      @clauses = [] of Clause
      @clauses.push(Clauses::Insert.new(table, transform_hash(values)))
      self
    end

    def insert(relation : Orb::Relation)
      @clauses = [] of Clause
      @clauses.push(Clauses::Insert.new(relation.class.table_name, relation.to_h))
      self
    end

    def join(table, columns)
      @clauses.push(Clauses::Join.new(table, columns, Joins::Inner))
      self
    end

    def inner_join(table, columns)
      @clauses.push(Clauses::Join.new(table, columns, Joins::Inner))
      self
    end

    def right_join(table, columns)
      @clauses.push(Clauses::Join.new(table, columns, Joins::Right))
      self
    end

    def left_join(table, columns)
      @clauses.push(Clauses::Join.new(table, columns, Joins::Left))
      self
    end

    def full_join(table, columns)
      @clauses.push(Clauses::Join.new(table, columns, Joins::Full))
      self
    end

    def cross_join(table, columns)
      @clauses.push(Clauses::Join.new(table, columns, Joins::Cross))
      self
    end

    def distinct(*columns)
      @clauses.reject!(Clauses::Distinct)
      @clauses.push(Clauses::Distinct.new(columns.to_a.map(&.to_s)))
      self
    end

    def select(fragment : Clauses::Fragment)
      @clauses.reject!(Clauses::Select)
      @clauses.push(Clauses::Select.new(fragment: fragment))
      self
    end

    def select(*columns)
      @clauses.reject!(Clauses::Select)
      @clauses.push(Clauses::Select.new(columns.to_a.map(&.to_s)))
      self
    end

    def select(klass : Orb::Relation.class)
      @clauses.reject!(Clauses::Select)
      @clauses.push(Clauses::Select.new(klass.column_names))
      @clauses.push(Clauses::From.new(klass.table_name))
      self
    end

    def group_by(*columns)
      @clauses.reject!(Clauses::GroupBy)
      @clauses.push(Clauses::GroupBy.new(columns.to_a.map(&.to_s)))
      self
    end

    def from(table)
      @clauses.reject!(Clauses::From)
      @clauses.push(Clauses::From.new(table.to_s))
      self
    end

    def order_by(col : String | Symbol)
      @clauses.reject!(Clauses::OrderBy)
      @clauses.push(
        Clauses::OrderBy.new([{col.to_s, "ASC"}])
      )
      self
    end

    def order_by(ordering : Array(Tuple(String, String)))
      @clauses.reject!(Clauses::OrderBy)
      @clauses.push(Clauses::OrderBy.new(ordering))
      self
    end

    def order_by(order_by : Array(Tuple(String, String)))
      @clauses.reject!(Clauses::OrderBy)
      @clauses.push(Clauses::OrderBy.new(order_by))
      self
    end

    def limit(value)
      @clauses.reject!(Clauses::Limit)
      @clauses.push(Clauses::Limit.new(value))
      self
    end

    def offset(value)
      @clauses.reject!(Clauses::Offset)
      @clauses.push(Clauses::Offset.new(value))
      self
    end

    {% for pair, _ in [{"where", "LogicalOperator::And"}, {"or_where", "LogicalOperator::Or"}] %}
      def {{pair[0].id}}(fragment : Clauses::Fragment)
        @clauses.push(Clauses::Where.new(fragment, {{pair[1].id}}))
        self
      end

      def {{pair[0].id}}(column, operator, value)
        if value.is_a?(Array)
          @clauses.push(Clauses::Where.new(column.to_s, operator.to_s.upcase, value.map(&.as(Orb::TYPES)), {{pair[1].id}}))
        else
          @clauses.push(Clauses::Where.new(column.to_s, operator.to_s.upcase, value, {{pair[1].id}}))
        end
        self
      end

      def {{pair[0].id}}(column, value)
        if value.is_a?(Array)
          @clauses.push(Clauses::Where.new(column.to_s, "IN", value.map(&.as(Orb::TYPES)), {{pair[1].id}}))
        else
          @clauses.push(Clauses::Where.new(column.to_s, "=", value, {{pair[1].id}}))
        end
        self
      end

      def {{pair[0].id}}(**conditions)
        clauses = conditions.to_a.map_with_index do |condition, i|
          operator = i.zero? ? {{pair[1].id}} : LogicalOperator::And
          value = condition[1]
          if value.is_a?(Array)
            Clauses::Where.new(condition[0].to_s, "IN", value.map(&.as(Orb::TYPES)), operator)
          else
            Clauses::Where.new(condition[0].to_s, "=", value, operator)
          end
        end

        @clauses.concat(clauses)
        self
      end
    {% end %}

    def to_result
      clauses = Clauses::CombineClause.new(@clauses).call.sort_by { |c| CLAUSE_PRIORITY[c.class] }
      values = clauses.flat_map(&.values)
      first_where_clause = clauses.find { |clause| clause.is_a?(Clauses::Where) }

      query = clauses.map_with_index do |clause, i|
        position = clauses[0...i].flat_map(&.values).size + 1

        if clause == first_where_clause
          "WHERE " + clause.to_sql(position)
        elsif clause.is_a?(Clauses::Where)
          clause.logical_operator + " " + clause.to_sql(position)
        else
          clause.to_sql(position)
        end
      end.join(" ")

      QueryResult.new(query: query.strip, values: values)
    end

    private def transform_hash(hash)
      new_hash = Hash(String | Symbol, Orb::TYPES).new
      hash.each { |key, val| new_hash.put(key, val) { } }
      new_hash
    end
  end
end
