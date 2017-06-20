require 'rails-assets-html2canvas'

module TranslationEngine
  class Engine < ::Rails::Engine
    isolate_namespace TranslationEngine

    initializer "translation_engine.middlewares" do |app|
      app.config.app_middleware.use TranslationEngine::CatcherMiddleware
      app.config.app_middleware.use TranslationEngine::KeysMiddleware
      app.config.app_middleware.use TranslationEngine::ScreenshotsMiddleware
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
          I18n.backend = TranslationEngine::Backend.new

          I18n::Backend::Fallbacks.module_eval do
            # Fixing problem in Fallback Backend!
            # https://github.com/svenfuchs/i18n/blob/master/lib/i18n/backend/fallbacks.rb#L37
            def translate(locale, key, options = {})
              return super unless options.fetch(:fallback, true)
              return super if (@fallback_locked ||= false)
              default = extract_non_symbol_default!(options) if options[:default]

              begin
                @fallback_locked = true
                I18n.fallbacks[locale].each do |fallback|
                  begin
                    catch(:exception) do
                      result = super(fallback, key, options)
                      return result if (result.nil? && options.key?(:default) && options[:default].nil?) || !result.nil?
                    end
                  rescue I18n::InvalidLocale
                    # we do nothing when the locale is invalid, as this is a fallback anyways.
                  end
                end
              ensure
                @fallback_locked = false
              end

              # Original code is:
              # return super(locale, nil, options.merge(:default => default)) if default
              # And fix is adding key:
              return super(locale, key, options.merge(:default => default)) if default

              throw(:exception, I18n::MissingTranslation.new(locale, key, options))
            end
          end

        end
      end
    end
  end
end

