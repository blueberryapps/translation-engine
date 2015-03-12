require 'faraday'

class Connection

  NotFound = Class.new(Exception)

  def send_images(data)
    connection.post do |req|
      req.url '/api/v1/images'
      req.headers['Content-Type']  = 'application/json'
      req.headers['Authorization'] = api_token
      req.body = data.to_json
    end
  end

  def send_translations(data)
    connection.post do |req|
      req.url '/api/v1/translations'
      req.headers['Content-Type']  = 'application/json'
      req.headers['Authorization'] = api_token
      req.body = data.to_json
    end
  end

  def get_releases
    response = connection.get do |req|
      req.url '/api/v1/releases.json'
      req.headers['Authorization'] = api_token
    end

    JSON.parse(response.body).with_indifferent_access[:releases].map do |args|
      Release.new args
    end
  end

  def get_release(version)
    response = connection.get do |req|
      req.url "/api/v1/releases/#{version}.yaml"
      req.headers['Authorization'] = api_token
    end

    raise NotFound, "Release #{version} Not found" if response.status != 200

    response
  end

  def get_translations
    connection.get do |req|
      req.url '/api/v1/translations.yaml'
      req.headers['Authorization'] = api_token
    end
  end

  def get_translations_head
    connection.head do |req|
      req.url '/api/v1/translations.yaml'
      req.headers['Authorization'] = api_token
    end
  end

  private

  def connection
    @connection ||= Faraday.new(:url => TranslationEngine.api_host) do |faraday|
      faraday.use ConnectionExceptionMiddleware
      faraday.adapter Faraday.default_adapter
      faraday.options.timeout = 5
      faraday.options.open_timeout = 20
    end
  end

  def api_token
    "Token token=#{TranslationEngine.api_key}"
  end
end
