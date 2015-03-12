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
      puts "Listing releases from: #{ENVied.TRANSLATIONS_API_HOST}"
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
end
