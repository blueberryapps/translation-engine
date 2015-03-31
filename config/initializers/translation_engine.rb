TranslationEngine.config do |config|
  config.api_key  = '4e75310553e4523c0e015606343e01c5'
  config.api_host = 'http://127.0.0.1:3000'
  config.use_screenshots  = false
  config.use_catcher      = false
  config.timeout          = 5
  config.raise_exceptions = Rails.env.development?
end
