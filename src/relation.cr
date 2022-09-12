require "db"
require "./orb"

module RelationQuery
  def select(*columns)
    @query.select(*columns)
    self
  end

  macro included
    {% fields = parse_type("#{@type.id}::Fields".gsub(/::Query/, "")).resolve.all_subclasses %}

      {% for pair, _ in [{"where", "LogicalOperator::And"}, {"or_where", "LogicalOperator::Or"}] %}
      def {{pair[0].id}}({{*fields.map do |field|
                             name = "#{field.name.id.underscore.split("::").last.id}"
                             "#{name.id} = Orb::Query::Special::None".id
                           end}})

        {% for field in fields %}
          {% name = field.name.id.underscore.split("::").last.id %}
          unless {{name.id}}.is_a?(Orb::Query::Special::None)
            if {{name.id}}.is_a?(Array)
              @query.{{pair[0].id}}({{ name.symbolize }}, "IN", {{ name.id }}.map(&.as(Orb::TYPES)))
            else
              @query.{{pair[0].id}}({{ name.symbolize }}, "=", {{ name.id }}.as?(Orb::TYPES))
            end
          end
        {% end %}
        self
      end

      def {{pair[0].id}}(fragment : Orb::Query::Fragment)
        @query.where(fragment)
        self
      end

      def {{pair[0].id}}(column, value)
        @query.where(column, value)
        self
      end

      def {{pair[0].id}}(column, operator, value)
        @query.where(column, operator, value)
      end
      {% end %}
    end

  def limit(number)
    @query.limit(number)
    self
  end

  def offset(number)
    @query.offset(number)
    self
  end

  def join(table, columns)
    @query.join(table, columns)
    self
  end

  def order_by(col)
    @query.order_by(col)
    self
  end

  def count
    @query.count
  end

  def commit
    @query.commit
  end

  def to_result
    @query.to_result
  end

  def to_a
    @query.to_a
  end
end

module Orb
  module Relation
    include DB::Serializable

    @@column_names = Array(String).new

    macro included
      class Fields
      end

      def self.query
        Query.new
      end

      def self.column_names
        @@column_names
      end
    end

    macro schema(table_name, &block)
      include DB::Serializable

      def self.table_name
        {{table_name}}
      end

      {{ yield }}
    end

    macro constructor
      def initialize({{*parse_type("#{@type.id}::Fields").resolve.all_subclasses.map do |field|
                         name = "@#{field.name.id.underscore.split("::").last.id}"
                         "#{name.id} = nil".id
                       end}})
      end

      class Query
        @query : Orb::Query

        alias Relation = {{ parse_type("#{@type.id}").resolve }}
        include RelationQuery

        def initialize
          @query = Orb::Query.new.select(Relation.column_names).from(Relation.table_name).map_to(Relation)
        end

        def delete
          @query.delete(Relation.table_name)
          self
        end
      end
    end

    macro attribute(name, type)
      @@column_names.push({{name}}.to_s)

      class {{ name.camelcase.id }} < Fields; end

      property {{name.id}} : {{type}}
    end

    def to_h : Hash(String | Symbol, Orb::TYPES)
      converted = {} of (String | Symbol) => Orb::TYPES
      hash_attr = {% begin %}
        {% h = {} of (String | Symbol) => Orb::TYPES %}
        {% instance_vars = @type.instance_vars.reject { |var| var.name == "orb_query" } %}
        {% unless instance_vars.empty? %}
          {% instance_vars.map(&.name).each { |field| h[field.stringify] = field.id } %}
          {{h}}
        {% else %}
          converted
        {% end %}
      {% end %}
      hash_attr.each { |k, v| converted[k] = v }
      converted
    end
  end
end
