require "../../src/orb"

module Orb
  class ExampleRelation < Orb::Relation
    table "users"

    attribute :id, Int32
    attribute :name, String?
    attribute :email, String?
  end
end
