require "kemal"
require "../src/koa" # Koa must be requried after Kemal

# Global definitions
Koa.init "Test API"
Koa.server "127.0.0.1:3000"

Koa.cookie_auth "cookie", "session-id"
Koa.basic_auth "basic"

Koa.define_tag "user", desc: "Operations on users"

# Define schemas
Koa.schema "image", Bytes, desc: "An image"

Koa.schema "matrix", [[Int32]]

Koa.schema "points", [{
  "longitude" => Int32,
  "latitude"  => Int32,
}]

Koa.schema "user", {
  "id"       => String,
  "username" => String,
  "friends"  => ["user"],
}

Koa.schema "post", {
  "id"       => String,
  "author"   => "user",
  "metadata" => {
    "timestamp" => Int64,
    "location"  => "points",
    "nsfw"      => Bool,
  },
  "content" => {
    "text"  => String,
    "media" => {
      "video" => [String?],
      "audio" => [String?],
      "image" => [String?],
    },
  },
}

# Route definitions
Koa.describe "Lists all users"
Koa.tag "user"
Koa.response 200, schema: ["user"]
get "/user" do |env|
end

Koa.describe "Returns a user with `id`"
Koa.response 404, "User not found"
Koa.response 200, schema: "user"
Koa.tag "user"
Koa.path "id", schema: Int32
get "/user/:id" do |env|
end

Koa.describe "Returns a user with `username`"
Koa.response 404, "User not found"
Koa.response 200, schema: "user"
Koa.tag "user"
get "/user/:username" do |env|
end

Koa.describe "Returns a list of users matching `query`"
Koa.tag "user"
Koa.query "query", schema: String
Koa.response 200, schema: {"users" => ["user"], "error" => String?}
get "/user/search" do |env|
end

Koa.describe "Creates a new user"
Koa.tags ["user", "auth"]
Koa.auth ["cookie", "basic"]
Koa.body desc: "A JSON string containing the new user", schema: "user"
post "/user" do |env|
end

Koa.describe "Returns the profile picture of a user with `id`"
Koa.tag "user"
Koa.path "id", schema: Int32
Koa.response 200, schema: "image", media_type: "image/*"
get "/profile_pic/{id}" do |env|
end

# Generates the OpenAPI description and prints it in YAML
puts Koa.generate.not_nil!.to_yaml
