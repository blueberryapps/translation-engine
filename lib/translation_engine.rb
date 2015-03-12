require "translation_engine/engine"

module TranslationEngine
  mattr_accessor :api_key, :api_host, :use_screenshots, :use_catcher, :raise_exceptions

 def self.config
    yield self
  end
end
