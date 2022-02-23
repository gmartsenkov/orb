require "../../src/orb"

module Orb
  class PostRelation < Orb::Relation
    table "posts"

    attribute :id, Int32?
    attribute :user_id, Int32?
    attribute :content, String?
    attribute :created_at, Time?

    def initialize(@id = nil, @user_id = nil, @content = nil, @created_at = nil)
    end
  end
end
