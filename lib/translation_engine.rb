require "translation_engine/engine"

module TranslationEngine
  mattr_accessor :api_key, :api_host, :timeout,
                 :use_screenshots, :use_catcher, :raise_exceptions,
                 :disable_sending_translations, :cache_timeout

 def self.config
    yield self
  end
end
