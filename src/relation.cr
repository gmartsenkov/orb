require "db"
require "./orb"

module Orb
  struct Relationship
    property name : String
    property relation : Orb::Relation.class
    property keys : Tuple(String, String)
    property association : Orb::Association

    def initialize(@name, @relation, @keys, @association)
    end
  end
end

module Orb
  enum Association
    OneToOne
  end
end

module Orb
  abstract class Relation
    include DB::Serializable

    @@column_names = Array(String).new
    @@relationships = Hash(String, Relationship).new

    macro table(name)
      include DB::Serializable

      def self.table_name
        {{name}}
      end
    end

    def self.combine(collection : Array(self), association : Symbol)
      {% begin %}
      case association.to_s
          {% for method in @type.class.methods.map(&.name).select { |m| m.stringify.starts_with?("combine_") } %}
          when {{method.stringify}}.delete("combine_")
            self.{{method.id}}(collection)
          {% end %}
      else
        puts "{{@type.class.methods.map(&.name)}}"
        raise "Association '#{association}' does not exist"
      end
      {%end%}
    end

    macro has_one(name, type, keys)
      @@relationships[{{name}}.to_s] = Relationship.new({{name.stringify}}, {{type}}, {{keys}}, Orb::Association::OneToOne)
      property {{name.id}} : {{type}}?

      def self.combine_{{name.id}}(collection : Array(self))
        collection_ids = collection.map(&.{{keys[0].id}})
        results = {{type}}.query.where({{keys[1]}}, collection_ids).to_a.as(Array({{type}})).group_by(&.{{keys[1].id}})
        collection.each do |el|
          result = results[el.{{keys[0].id}}]?
          el.{{name.id}} = result.first if result
        end
      end
    end

    macro attribute(name, type)
      @@column_names.push({{name}}.to_s)
      property {{name.id}} : {{type}}
    end

    def to_h : Hash(String | Symbol, Orb::TYPES)
      converted = {} of (String | Symbol) => Orb::TYPES
      hash_attr = {% begin %}
        {% h = {} of (String | Symbol) => Orb::TYPES %}
        {% unless @type.instance_vars.empty? %}
          {% @type.instance_vars.map(&.name).each { |field| h[field.stringify] = field.id } %}
          {{h}}
        {% else %}
          converted
        {% end %}
      {% end %}
      hash_attr
        .reject { |k, _v| @@relationships.keys.includes?(k) }
        .each { |k, v| converted[k] = v unless v.is_a?(Orb::Relation) }
      converted
    end

    def self.query
      Orb::Query(self).new.select(self)
    end

    def self.column_names
      @@column_names
    end

    def self.relationships
      @@relationships
    end
  end
end
