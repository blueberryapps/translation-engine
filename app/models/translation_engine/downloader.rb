require 'fileutils'

class TranslationEngine::Downloader

  def self.etag?(etag)
    response = @current_etag == etag
    Rails.logger.info { "Translations are up to date" } if response
    @current_etag = etag
    @cache_timeout = Time.now + TranslationEngine.cache_timeout
    response
  end

  def self.cache_timeout
    @cache_timeout
  end

  def update
    return nil if self.class.cache_timeout && Time.now < self.class.cache_timeout
    return nil if self.class.etag?(connection.get_translations_head[:etag])
    I18n.backend.reload!
  end

  def store
    if (yml_data = receive_translations)
      Rails.logger.info { "Storing translations to #{locale_file}" }
      write(locale_file, yml_data)
      add_translation_file_to_i18n
      I18n.backend.reload!
    end
  end

  def store_release(release)
    locale = release.split('_')[0...-1].join('_')
    filename = releases_dir.join("#{locale.downcase}.yml")
    if (yml_data = connection.get_release(release).try(:body))
      Rails.logger.info { "Storing release #{release} to #{filename}" }
      write(filename, yml_data)
    end
  end

  private

  def add_translation_file_to_i18n
    unless I18n.load_path.include?(locale_file)
      I18n.load_path += [locale_file]
    end
  end

  def connection
    @connection ||= TranslationEngine::Connection.new
  end

  def locale_dir
    Rails.root.join('config', 'locales')
  end

  def locale_file
    locale_dir.join('z_translation_engine.yml')
  end

  def receive_translations
    return if self.class.etag?(connection.get_translations_head[:etag])

    connection.get_translations.try(:body)
  end

  def releases_dir
    dir = Rails.root.join('config', 'locales', 'z_releases')
    FileUtils.mkdir_p(dir) unless File.exists?(dir)
    dir
  end

  def write(filename, data)
    File.open(filename, 'wb') do |f|
      f.write data
    end
  end
end
