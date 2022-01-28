require "db"
require "./orb"

module Orb
  abstract class Relation
    include DB::Serializable

    @@column_names = Array(String).new

    macro table(name)
      include DB::Serializable

      def self.table_name
        {{name}}
      end
    end

    macro attribute(name, type)
      @@column_names.push({{name}}.to_s)
      property {{name.id}} : {{type}}
    end

    def to_h : Hash(String | Symbol, Orb::TYPES)
      hash = {{ @type.instance_vars.map(&.name).map { |field| [field.stringify, field.id] } }}.to_h
      new = Hash(String | Symbol, Orb::TYPES).new
      hash.each { |k, v| k.is_a?(String) ? new.put(k.as(String), v) { } : nil }
      new
    end

    def self.column_names
      @@column_names
    end
  end
end
