module TranslationEngine
  class KeysMiddleware

    URL_PATH = /\A\/translation_engine\/keys/

    def initialize(app)
      @app = app
    end

    def call(env)
      if env['PATH_INFO'] =~ URL_PATH
        handle_redirect_request(env)
      else
        @app.call(env)
      end
    end

    private

    def handle_redirect_request(env)
      key_path = env['PATH_INFO'].gsub(URL_PATH, '')

      [
        302,
        {
          'Location' => "#{TranslationEngine.api_host}/#{key_path}",
          'Content-Type' => 'text/html'
        },
        ['Moved Temporarily']
      ]
    end
  end
end
