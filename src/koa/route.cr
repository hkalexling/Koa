struct Koa
  @@temp_hash = {} of String => String | Array(String) |
                                Array(OpenAPI::Parameter) |
                                Hash(String, OpenAPI::Response) |
                                OpenAPI::RequestBody | Nil

  # Sets `summary` and `description` (optional) of the succeeding route.
  def self.describe(summary : String, desc : String? = nil)
    @@temp_hash["summary"] = summary
    @@temp_hash["desc"] = desc
  end

  # Adds a tag to the succeeding route.
  def self.tag(tag : String)
    @@temp_hash["tags"] = [] of String unless @@temp_hash["tags"]?
    @@temp_hash["tags"].as(Array(String)) << tag
  end

  # Sets the tags of the succeeding route.
  def self.tags(tags : Array(String))
    @@temp_hash["tags"] = tags
  end

  # Adds a response to the succeeding route.
  #
  # The response {"200" => "OK"} is automatically added, and you can overwrite it with `Koa.response "200", "New description"`.
  def self.response(status : UInt32, desc : String, *, ref : String? = nil,
                    media_type = "application/json")
    @@temp_hash["responses"] = {"200" => OpenAPI.response description: "OK"} \
      unless @@temp_hash["responses"]?

    content = nil
    if ref
      ref = ref[1..-1] if ref.starts_with? "$"
      schema = OpenAPI.reference ref: "#/components/schemas/#{ref}"
      content = {media_type => OpenAPI.media_type schema: schema}
    end

    @@temp_hash["responses"].as(Hash(String, OpenAPI::Response))[status.to_s] =
      OpenAPI.response description: desc, content: content
  end

  # Adds a registered authentication method to the succeeding route.
  def self.auth(key : String)
    @@temp_hash["auth"] = [] of String unless @@temp_hash["auth"]?
    @@temp_hash["auth"].as(Array(String)) << key
  end

  # Sets the list of authentication methods of the succeeding route.
  def self.auth(keys : Array(String))
    @@temp_hash["auth"] = keys
  end

  # Specifies the required request body of the succeeding route.
  def self.body(type : String, *, required = true, desc : String? = nil,
                ref : String? = nil)
    schema = nil
    if ref
      ref = ref[1..-1] if ref.starts_with? "$"
      schema = OpenAPI.reference ref: "#/components/schemas/#{ref}"
    end
    @@temp_hash["body"] = OpenAPI.request_body description: desc,
      required: required, content: {type => OpenAPI.media_type schema: schema}
  end

  {% for type in %w(query path header cookie) %}
  # Adds a {{type.id}} parameter to the succeeding route.
  def self.{{type.id}}(name : String, *, desc : String? = nil, required = true,
                      type : String = "string", low_priority = false)
    param = OpenAPI.parameter name: name, in: {{type}}, description: desc,
      required: required, schema: OpenAPI.schema type: type
    @@temp_hash["params"] = [] of OpenAPI::Parameter \
      unless @@temp_hash["params"]?

    ary = @@temp_hash["params"].as(Array(OpenAPI::Parameter))

    return if low_priority && ary.any? {|p| p.in == {{type}} && p.name == name}

    ary.reject! do |p|
      p.in == {{type}} && p.name == name
    end

    ary << param
  end
  {% end %}

  {% for method in %w(get post put patch delete options) %}
  # Registers a {{method.id}} route.
  #
  # This method will be invoked by the monkey-patched Kemal, and you don't need to call it manually.
  def self.{{method.id}}(path : String)
    path_params = [] of String
    path.scan /\/(:([^ \/\r\n]+))/ do |match|
      path = path.gsub match[1], "{#{match[2]}}"
      path_params << match[2]
    end

    path_params.each {|p| self.path p, low_priority: true}

    @@temp_hash["responses"] = {"200" => OpenAPI.response description: "OK"} \
      unless @@temp_hash["responses"]?

    auth = nil
    if @@temp_hash["auth"]?
      auth = @@temp_hash["auth"].as(Array(String)).map do |key|
        {key => [] of String}
      end
    end

    @@paths[path] = OpenAPI.path_item unless @@paths[path]?
    @@paths[path].{{method.id}} = OpenAPI.operation \
      tags: @@temp_hash["tags"]?.as Array(String)?,
      summary: @@temp_hash["summary"]?.as String?,
      description: @@temp_hash["desc"]?.as String?,
      parameters: @@temp_hash["params"]?.as Array(OpenAPI::Parameter)?,
      responses: @@temp_hash["responses"].as Hash(String, OpenAPI::Response),
      security: auth,
      request_body: @@temp_hash["body"]?.as OpenAPI::RequestBody?

    @@temp_hash.clear
  end
  {% end %}
end
