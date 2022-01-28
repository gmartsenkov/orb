require "../../src/orb"

module Orb
  class ExampleRelation < Orb::Relation
    table "users"

    attribute :id, Int32
    attribute :name, String?
    attribute :email, String?
    attribute :created_at, Time?

    def initialize(@id, @name, @email, @created_at)
    end
  end
end
