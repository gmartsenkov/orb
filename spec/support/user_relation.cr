require "../../src/orb"
require "./avatars_relation"

module Orb
  class UserRelation < Orb::Relation
    table "users"

    attribute :id, Int32?
    attribute :name, String?
    attribute :email, String?
    attribute :created_at, Time?

    has_one :avatar, Orb::AvatarsRelation, {"id", "user_id"}

    register_associations

    def initialize(@id = nil, @name = nil, @email = nil, @created_at = nil, @avatar = nil)
    end
  end
end
