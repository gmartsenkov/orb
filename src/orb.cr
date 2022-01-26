require "json"
require "uuid"
require "./relation"

module Orb
  VERSION = "0.1.0"
  alias TYPES = String | Nil | Bool | Int32 | Float32 | Float64 | Time | JSON::Any | UUID
end
