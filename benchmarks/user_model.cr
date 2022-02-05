require "clear"

class UserModel
  include Clear::Model

  self.table = "users"

  column name : String
  column email : String?
  column created_at : String?

  column id : Int32, primary: true, presence: false
end
