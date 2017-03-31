module TranslationEngine
  class SendTranslationsJob < ActiveJob::Base
    queue_as :translation_engine

    def perform(location, ip)
      data = {
        location:     location,
        locale:       I18n.locale,
        translations: TranslationEngine::Translation.catched.uniq
      }

      TranslationEngine::Connection.new.send_translations(data, ip)
    end
  end
end
