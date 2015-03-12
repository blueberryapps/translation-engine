class Backend < I18n::Backend::Simple

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
    connection.get_releases
  end

  def current_locale_releases
    releases.select(&:current_locale?)
  end

  protected

  def connection
    @connection ||= Connection.new
  end

  def download_master
    if (yml_data = connection.get_translations.body)
      Rails.logger.info { 'Updating from translation server - master' }
      YAML.load(yml_data).each do |locale, translations|
        store_translations locale, translations
      end
    end
  end

  def download_release
    if (yml_data = connection.get_release(release).body)
      Rails.logger.info { "Updating from translation server - #{release}" }
      YAML.load(yml_data).each do |locale, translations|
        store_translations locale, translations
      end
    end
  end

  def lookup(locale, key, scope = [], options = {})
    keys = I18n.normalize_keys(locale, key, scope, options[:separator])
    resolved = super
    if resolved
      enhance_translation(resolved, keys)
    else
      resolved
    end
  end

  def enhance_translation(value, main_keys, catch_translation = true)
    return value if (main_keys & IGNORE_KEYS).any?

    case value
    when Array
      Translation.catch(value, main_keys)
      value.map { |v| enhance_translation(v, main_keys, false) }
    when Hash
      Hash[value.map { |k, v| [k, enhance_translation(v, main_keys + [k])] }]
    when String
      Translation.new(value, main_keys).to_s
    else
      Translation.catch(value, main_keys) if catch_translation
      value
    end
  end
end
