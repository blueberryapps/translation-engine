require 'rails-assets-html2canvas'

module TranslationEngine
  class Engine < ::Rails::Engine
    isolate_namespace TranslationEngine

    initializer "translation_engine.middlewares" do |app|
      app.config.app_middleware.use CatcherMiddleware
      app.config.app_middleware.use ScreenshotsMiddleware
    end

    initializer "translation_engine.assets.precompile" do |app|
      app.config.assets.precompile += %w(
        translation_engine/screenshots.css
        translation_engine/screenshots.js
      )
      %w(stylesheets javascripts).each do |sub|
        app.config.assets.paths << root.join('app', 'assets', sub).to_s
      end
    end

    if !Rails.const_defined?('Console')
      config.after_initialize do |app|
        if TranslationEngine.use_catcher || TranslationEngine.use_screenshots
          I18n.backend = Backend.new
        end
      end
    end
  end
end

