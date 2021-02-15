require "open_api"
require "./koa/*"

struct Koa
  class SchemaError < Exception
  end

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

  private def self.parse_primitive_type(type : PrimitiveType,
                                        desc : String? = nil) : Schema
    {% begin %}
    case type
    {% for k, v in TYPES %}
    when {{k.id}}?.class, {{k.id}}.class
      _type, format = {{v}}
      schema = OpenAPI.schema type: _type, format: format
      required = !type.nilable?
    {% end %}
    when String
      schema = OpenAPI.reference ref: "#/components/schemas/#{type.lstrip "$"}"
      required = !type.ends_with? "?"
    else
      raise SchemaError.new "Unknow schema type #{type}"
    end
    {schema: schema, required: required}
    {% end %}
  end

  private def self.parse_type(type : Type, desc : String? = nil) : Schema
    case type
    when PrimitiveType
      return parse_primitive_type type, desc
    when Array
      unless type.size == 1
        raise SchemaError.new "A schema definition of type Array should " \
                              "contain one and only one element"
      end
      item = parse_type type.first
      schema = OpenAPI.schema type: "array", items: item[:schema]
      required = item[:required]
    when Hash
      schemas = Hash.zip type.keys, type.values.map { |v|
        parse_type(v).as Schema
      }
      props = Hash.zip schemas.keys.map &.rstrip("?"),
        schemas.values.map &.[:schema]
      requires = schemas
        .select do |k, v|
          v[:required] && !k.ends_with? "?"
        end
        .keys
      requires = nil if requires.empty?
      schema = OpenAPI.schema type: "object", properties: props,
        required: requires
      required = true
    else
      raise SchemaError.new "Unknow schema type #{type}"
    end
    {schema: schema, required: required}
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
