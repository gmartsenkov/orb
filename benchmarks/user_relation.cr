require "../src/orb"

class UserRelation < Orb::Relation
  table "users"

  attribute :id, Int32?
  attribute :name, String?
  attribute :email, String?
  attribute :created_at, Time?

  def initialize(@id = nil, @name = nil, @email = nil, @created_at = nil)
  end
end