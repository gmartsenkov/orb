require "json"
require "uuid"
require "db"
require "./relation"
require "./query"

module Orb
  VERSION = "0.1.0"
  alias TYPES = String | Nil | Bool | Int32 | Float32 | Float64 | Time | JSON::Any | UUID

  extend self

  @@db : DB::Database?
  @@conn : DB::Database | DB::Connection | Nil

  def connect(url)
    @@db = DB.open(url)
  end

  def db
    @@db.not_nil!
  end

  def conn=(conn)
    @@conn = conn
  end

  def conn
    (@@conn || @@db).not_nil!
  end

  def query(query, klass)
    query_result = query.to_result
    klass.from_rs(conn.query(query_result.query, args: query_result.values))
  end

  def exec(query)
    query_result = query.to_result
    conn.exec(query_result.query, args: query_result.values)
  end

  def scalar(query)
    query_result = query.to_result
    conn.scalar(query_result.query, args: query_result.values).as(Int64)
  end

  def disconnect
    @@db.try(&.close)
  end
end
