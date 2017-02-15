require 'faraday'

class TranslationEngine::Connection

  NotFound = Class.new(Exception)

  def send_images(data, ip_address = nil)
    connection.post do |req|
      req.url '/api/v1/images'
      req.headers['Content-Type']  = 'application/json'
      req.headers['Authorization'] = api_token
      req.headers['Original-IP-Address'] = ip_address if ip_address.present?
      req.body = data.to_json
    end
  end

  def send_translations(data, ip_address = nil)
    puts "Sending translations in separate thread"
    connection(60).post do |req|
      req.url '/api/v1/translations'
      req.headers['Content-Type'] = 'application/json'
      req.headers['Original-IP-Address'] = ip_address if ip_address.present?
      req.headers['Authorization'] = api_token
      req.body = data.to_json
    end
    puts "Sending translations in separate thread finished"
  rescue StandardError => e
    puts "Sending translations failed: #{e.class}: #{e.message}"
  end

  def get_releases
    response = connection.get do |req|
      req.url '/api/v1/releases.json'
      req.headers['Authorization'] = api_token
    end

    JSON.parse(response.body).with_indifferent_access[:releases].map do |args|
      TranslationEngine::Release.new args
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

  def connection(timeout = TranslationEngine.timeout)
    Thread.current[:translation_server_connection] ||= Faraday.new(:url => TranslationEngine.api_host) do |faraday|
      faraday.use TranslationEngine::ConnectionExceptionMiddleware
      faraday.adapter Faraday.default_adapter
      faraday.options.timeout      = timeout
      faraday.options.open_timeout = TranslationEngine.timeout * 4
    end
  end

  def api_token
    "Token token=#{TranslationEngine.api_key}"
  end
end
