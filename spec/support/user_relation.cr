require "../../src/orb"
require "./avatars_relation"
require "./post_relation"

module Orb
  class UserRelation < Orb::Relation
    table "users"

    attribute :id, Int32?
    attribute :name, String?
    attribute :email, String?
    attribute :created_at, Time?

    has_one :avatar, Orb::AvatarsRelation, {"id", "user_id"}
    has_many :posts, Orb::PostRelation, {"id", "user_id"}

    def initialize(@id = nil, @name = nil, @email = nil, @created_at = nil, @avatar = nil)
    end
  end
end
