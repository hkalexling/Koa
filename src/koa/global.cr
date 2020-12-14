struct Koa
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

  # Defines an array schema
  def self.array(name : String, type : String, *, desc : String? = nil)
    if type.starts_with? "$"
      items = OpenAPI.reference ref: "#/components/schemas/#{type[1..-1]}"
    else
      items = OpenAPI.schema type: type
    end
    @@schemas[name] = OpenAPI.schema type: "array", description: desc,
      items: items
  end

  # Defines an object schema
  def self.object(name : String, schema : Hash(String, String), *,
                  desc : String? = nil)
    props = {} of String => OpenAPI::Schema | OpenAPI::Reference
    requires = [] of String
    schema.each do |key, type|
      if type.ends_with? "?"
        type = type[0..-2]
      else
        requires << key
      end

      if type.starts_with? "$"
        prop = OpenAPI.reference ref: "#/components/schemas/#{type[1..-1]}"
      else
        prop = OpenAPI.schema type: type
      end
      props[key] = prop
    end
    @@schemas[name] = OpenAPI.schema type: "object", description: desc,
      properties: props, required: requires
  end

  # Defines a binary schema
  def self.binary(name : String, *, desc : String? = nil)
    @@schemas[name] = OpenAPI.schema type: "string", description: desc,
      format: "binary"
  end
end
