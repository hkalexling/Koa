struct Koa
  TYPES = {
    String  => {"string", nil},
    Bool    => {"boolean", nil},
    Int32   => {"integer", "int32"},
    Int64   => {"integer", "int64"},
    Float32 => {"number", "float"},
    Float64 => {"number", "double"},
    Bytes   => {"string", "binary"},
    Base64  => {"string", "byte"},
  }

  {% begin %}
    alias PrimitiveType = {% for t in TYPES.keys %}
      ({{t.id}} | Nil).class | {{t.id}}.class |
    {% end %} String
    alias Type = PrimitiveType | Array(Type) | Hash(String, Type)
  {% end %}

  alias Schema = NamedTuple(schema: OpenAPI::Schema | OpenAPI::Reference,
    required: Bool)

  # Initializes Koa and sets the `Info` object of the API.
  def self.init(title : String, *, desc : String? = nil, version = "1.0.0")
    @@info = OpenAPI.info title: title, description: desc, version: version
    @@paths.clear
  end

  # Adds a server to the server list.
  def self.server(url : String, desc : String? = nil)
    @@servers << OpenAPI.server url: url, description: desc
  end

  # Adds a API Key authentication method.
  def self.cookie_auth(key : String, name : String)
    @@security_schemes[key] = OpenAPI.security_scheme type: "apiKey",
      in: "cookie", name: name
  end

  # Adds a Basic authentication method.
  def self.basic_auth(key : String)
    @@security_schemes[key] = OpenAPI.security_scheme type: "http",
      scheme: "basic"
  end

  # Adds a Bearer authentication method.
  def self.bearer_auth(key : String, format : String)
    @@security_schemes[key] = OpenAPI.security_scheme type: "http",
      scheme: "bearer", bearer_format: format
  end

  # Defines a schema
  def self.schema(name : String, type : Type, *, desc : String? = nil)
    schema = parse_type(type, desc)[:schema]
    if schema.is_a? OpenAPI::Reference
      raise SchemaError.new "Schema definition cannot be a simple wrapper " \
                            "around another schema"
    end
    @@schemas[name] = schema
  end

  # Defines a tag
  def self.define_tag(name : String, *, desc : String? = nil)
    @@tags << OpenAPI.tag name: name, description: desc
  end
end
