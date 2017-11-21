namespace :translation_engine do
  namespace :pull do

    desc 'Download all master translations from Translations server and ' +
         'store them into config/locales/z_translation_engine.yml'
    task master: :environment do
      TranslationEngine::Downloader.new.store
      puts 'Downloaded translations to: config/locales/z_translation_engine.yml'
    end

    desc 'Download released translations from Translations server and ' +
         'store them into config/locales/z_releases/LOCALE.yml, ' +
         'will overwrite previous locale release, leaving allways only one.'
    task release: :environment do
      Rails.logger = Logger.new(STDOUT)
      TranslationEngine::Downloader.new.store_release(ENV['RELEASE'])
    end
  end

  namespace :list do
    desc 'List all available releases from Translations Server'
    task releases: :environment do
      puts "Listing releases from: #{TranslationEngine.api_host}"
      releases = TranslationEngine::Connection.new.get_releases

      releases_hash = Hash.new { |h, k| h[k] = [] }

      releases.each_with_object(releases_hash) do |release, hash|
        hash[release.locale] << release
      end

      releases_hash.each do |locale, releases|
        puts "LOCALE: #{locale}"
        releases.each do |release|
          print "  #{release.version} - #{release.created_at}"
          print ' -> `rake translation_engine:pull:release '
          puts "RELEASE=#{release.version}`"
        end
      end
    end
  end

  desc 'Send all translations from directory config/locales/LOCALE ' +
       'to translations server'
  task push: :environment do
    locale = ENV['LOCALE'] || 'default'
    puts "\nLOCALE: #{locale}"

    TranslationEngine.timeout = 1000

    def to_dotted_hash(hash, recursive_key = [])
      hash.each_with_object({}) do |(k, v), ret|
        key = recursive_key + [k]
        if v.is_a? Hash
          ret.merge! to_dotted_hash(v, key)
        else
          ret[key] = v
        end
      end
    end
    dir = Rails.root.join('config', 'locales')

    Dir[dir.join "#{locale}/**/*.{yml}"].each do |file|
      unless file.include?('faker')
        hash = YAML.load_file(file) || {}
        to_dotted_hash(hash).each do |keys, text|
          TranslationEngine::Translation.catch text, keys
        end
      end
    end

    if TranslationEngine::Translation.catched.any?
      data = {
        locale:       locale,
        translations: TranslationEngine::Translation.catched.uniq
      }
      puts "Send #{TranslationEngine::Translation.catched.size} translations"
      TranslationEngine::Connection.new.send_translations(data)
    else
      puts "No translations was found and send"
    end
  end
end
