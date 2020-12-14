require "kemal"
require "../src/koa" # Koa must be requried after Kemal

# Global definitions
Koa.init "Test API"
Koa.server "127.0.0.1:3000"

Koa.cookie_auth "cookie", "session-id"
Koa.basic_auth "basic"

Koa.global_tag "user", desc: "Operations on users"

Koa.object "user", {"id" => "string", "username" => "string", "friends" => "$userAry"}
Koa.array "userAry", "$user"
Koa.binary "image", desc: "An image"

# Route definitions
Koa.describe "Lists all users"
Koa.tag "user"
Koa.response 200, ref: "$userAry"
get "/user" do |env|
end

Koa.describe "Returns a user with `id`"
Koa.response 404, "User not found"
Koa.response 200, ref: "$user"
Koa.tag "user"
Koa.path "id", type: "integer"
get "/user/:id" do |env|
end

Koa.describe "Returns a user with `username`"
Koa.response 404, "User not found"
Koa.response 200, ref: "$user"
Koa.tag "user"
get "/user/:username" do |env|
end

Koa.describe "Creates a new user"
Koa.tags ["user", "auth"]
Koa.auth ["cookie", "basic"]
Koa.body desc: "A JSON string containing the new user", ref: "$user"
post "/user" do |env|
end

Koa.describe "Returns the profile picture of a user with `id`"
Koa.tag "user"
Koa.path "id", type: "integer"
Koa.response 200, ref: "$image", media_type: "image/*"
get "/profile_pic/{id}" do |env|
end

# Generates the OpenAPI description and prints it in YAML
puts Koa.generate.not_nil!.to_yaml
