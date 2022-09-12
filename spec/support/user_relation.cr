require "../../src/orb"

module Orb
  class UserRelation
    include Orb::Relation

    schema("users") do
      attribute :id, Int32?
      attribute :name, String?
      attribute :email, String?
      attribute :created_at, Time?
    end

    constructor
  end
end
