module TranslationEngine
  class CatcherMiddleware
    include Request

    REMOVE_QUERY = /\?.*/
    REPLACE_IDS = /\d+/

    def initialize(app)
      @app = app
    end

    def call(env)
      if TranslationEngine.use_catcher && !assets_request?(env)
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

      begin
        update_translations
      rescue StandardError => e
        puts "Unable to update translations #{e.class} #{e.message}"
      end

      response = @app.call(env)

      unless TranslationEngine.disable_sending_translations
        begin
          send_translations(env)
        rescue StandardError => e
          puts "Unable to send new translations #{e.class} #{e.message}"
        end
      end

      response
    end

    def assets_request?(env)
      env['PATH_INFO'] =~ /\/assets/ ||                  # AssetPipeline
        env['PATH_INFO'] =~ /\/rails\/active_storage/ || # ActiveStorage
        env['PATH_INFO'] =~ /\/attachments/              # Refile
    end

    def params(env)
      Rack::Utils.parse_query(env['QUERY_STRING'], '&')
    end

    def update_translations
      translation_downloader.update
    end

    def send_translations(env)
      return if TranslationEngine::Translation.catched.empty?

      location = env['PATH_INFO'].gsub(REMOVE_QUERY, '').gsub(REPLACE_IDS, ':id')

      data = {
        location:     location,
        locale:       I18n.locale,
        translations: TranslationEngine::Translation.catched.uniq
      }

      Thread.new { TranslationEngine::Connection.new.send_translations(data, remote_ip(env)) }
    end

    def translation_downloader
      @translation_downloader ||= TranslationEngine::Downloader.new
    end
  end
end
