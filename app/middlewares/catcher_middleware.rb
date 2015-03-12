class CatcherMiddleware

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
    Translation.clear_catched

    if env['QUERY_STRING'].include?('translation_release')
      I18n.backend.release = params(env)['translation_release']
    end

    update_translations unless assets_request?(env)

    response = @app.call(env)

    send_translations(env)

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

  def send_translations(env)
    return if Translation.catched.empty?

    data = {
      location:     env['PATH_INFO'],
      locale:       I18n.locale,
      translations: Translation.catched.uniq
    }

    Connection.new.send_translations(data)
  end

  def translation_downloader
    @translation_downloader ||= TranslationEngine::Downloader.new
  end
end
