$:.push File.expand_path('../lib', __FILE__)

# Maintain your gem's version:
require 'translation_engine/version'

# Describe your gem and declare its dependencies:
Gem::Specification.new do |s|
  s.name        = 'translation_engine'
  s.version     = TranslationEngine::VERSION
  s.authors     = ['Ondrej Bartas']
  s.email       = ['ondrej@bartas.cz']
  s.homepage    = 'http://blueberry.cz'
  s.summary     = 'Connects Rails application to Translation Server'
  s.description = 'Description of TranslationEngine.'
  s.license     = 'MIT'

  s.files = Dir['{app,config,db,lib}/**/*', 'MIT-LICENSE', 'Rakefile', 'README.rdoc']
  s.test_files = Dir['test/**/*']

  s.add_dependency 'rails', '>= 4.2.0'
  s.add_dependency 'faraday'

  s.add_development_dependency 'sqlite3'
  s.add_development_dependency 'coffee-rails'
  s.add_development_dependency 'jquery-rails'
end
