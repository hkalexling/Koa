require "open_api"
require "./koa/*"

struct Koa
  @@info : OpenAPI::Info?
  @@servers = [] of OpenAPI::Server
  @@paths = {} of String => OpenAPI::PathItem
  @@security_schemes = {} of String => OpenAPI::SecurityScheme
  @@schemas = {} of String => OpenAPI::Schema
  @@tags = [] of OpenAPI::Tag

  # Generates an instance of `OpenAPI::Document` that contains the API specification.
  #
  # You can get the YAML or JSON representation using `to_yaml` or `to_json`
  def self.generate : OpenAPI::Document?
    unless @@info
      Log.error { "Please call `Koa.init` before defining your routes" }
      return
    end

    components = nil
    if @@security_schemes || @@schemas
      components = OpenAPI.components security_schemes: @@security_schemes,
        schemas: @@schemas
    end
    OpenAPI.document openapi: "3.0.0", info: @@info.not_nil!,
      servers: @@servers, paths: @@paths, components: components, tags: @@tags
  end
end

# Monkey-patch the Kemal DSL
{% for method in %w(get post put patch delete options) %}
  # :nodoc:
  def {{method.id}}(path : String, &block : HTTP::Server::Context -> _)
    previous_def path, &block
    Koa.{{method.id}} path
  end
{% end %}
