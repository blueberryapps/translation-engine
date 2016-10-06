require 'faraday'

class TranslationEngine::ConnectionExceptionMiddleware < Faraday::Middleware
  def call(env)
    begin
      @app.call(env)
    rescue Faraday::Error => e
      message = "Connecting to TranslationServer got #{e.class}: #{e.message}"

      if TranslationEngine.raise_exceptions
        raise TranslationEngine::ConnectionError, message
      else
        Rails.logger.error { message }
        {}
      end
    end
  end
end
