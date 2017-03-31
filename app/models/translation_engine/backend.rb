class TranslationEngine::Backend < I18n::Backend::Simple

  IGNORE_KEYS = %i(faker order)

  def reload!
    super
    init_translations
    release == 'master' ? download_master : download_release
  end

  def release=(release)
    @release = release
    reload!
    release
  end

  def release
    @release ||= 'master'
  end

  def releases
    [TranslationEngine::Release.master] | connection.get_releases
  end

  def current_locale_releases
    releases.select(&:current_locale?)
  end

  protected

  def connection
    @connection ||= TranslationEngine::Connection.new
  end

  def download_master
    if (yml_data = connection.get_translations.try(:body))
      Rails.logger.info { 'Updating from translation server - master' }
      YAML.load(yml_data).each do |locale, translations|
        store_translations locale, translations
      end
    end
  end

  def download_release
    if (yml_data = connection.get_release(release).try(:body))
      Rails.logger.info { "Updating from translation server - #{release}" }
      YAML.load(yml_data).each do |locale, translations|
        store_translations locale, translations
      end
    end
  end

  def resolve(locale, object, subject, options = {})
    return subject if options[:resolve] == false

    result = catch(:exception) do
      case subject
      when Symbol
        I18n.translate(subject, options.merge(:locale => locale, :throw => true))
      when Proc
        date_or_time = options.delete(:object) || object
        resolve(locale, object, subject.call(date_or_time, options))
      when nil
        nil
      else
        keys = I18n.normalize_keys(locale, object, options[:scope], options[:separator])
        enhance_translation(subject, keys)
      end
    end
    result unless result.is_a?(I18n::MissingTranslation)
  end

  def enhance_translation(value, main_keys, catch_translation = true)
    return value if (main_keys & IGNORE_KEYS).any?

    case value
    when Array
      TranslationEngine::Translation.catch(value, main_keys)
      value.map { |v| enhance_translation(v, main_keys, false) }
    when Hash
      Hash[value.map { |k, v| [k, enhance_translation(v, main_keys + [k])] }]
    when String
      TranslationEngine::Translation.new(value, main_keys).to_s
    else
      TranslationEngine::Translation.catch(value, main_keys) if catch_translation
      value
    end
  end
end
