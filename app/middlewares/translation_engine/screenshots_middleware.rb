class TranslationEngine::ScreenshotsMiddleware

  URL_PATH = /\A\/translation_engine\/screenshots/

  def initialize(app)
    @app = app
  end

  def call(env)
    if TranslationEngine.use_screenshots && env['PATH_INFO'] =~ URL_PATH
      handle_translation_request(env)
    else
      @app.call(env)
    end
  end

  private

  def handle_translation_request(env)
    data = JSON.parse(env["rack.input"].read)

    TranslationEngine::Connection.new
      .send_images(data.merge(locale: I18n.locale))

    [
      200,
      { 'Content-Type' => 'application/json' },
      [{ message: 'translations saved' }.to_json]
    ]
  end
end
