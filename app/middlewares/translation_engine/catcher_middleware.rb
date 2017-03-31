module TranslationEngine
  class CatcherMiddleware
    include Request

    REMOVE_QUERY = /\?.*/
    REPLACE_IDS = /\d+/

    def initialize(app)
      @app = app
    end

    def call(env)
      if TranslationEngine.use_catcher
        call_catcher(env)
      else
        @app.call(env)
      end
    end

    private

    def call_catcher(env)
      TranslationEngine::Translation.clear_catched

      if env['QUERY_STRING'].include?('translation_release')
        I18n.backend.release = params(env)['translation_release']
      end

      update_translations unless assets_request?(env)

      response = @app.call(env)

      unless TranslationEngine::Translation.catched.empty?
        location = env['PATH_INFO'].gsub(REMOVE_QUERY, '').gsub(REPLACE_IDS, ':id')
        ip       = remote_ip(env)
        TranslationEngine::SendTranslationsJob.perform_later(location, ip)
      end

      response
    end

    def assets_request?(env)
      env['PATH_INFO'] =~ /\/assets/
    end

    def params(env)
      Rack::Utils.parse_query(env['QUERY_STRING'], '&')
    end

    def update_translations
      translation_downloader.update
    end

    def translation_downloader
      @translation_downloader ||= TranslationEngine::Downloader.new
    end
  end
end
