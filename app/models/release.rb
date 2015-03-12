class Release

  attr_accessor :version, :locale, :created_at

  def self.master
    new(
      version:    'master',
      locale:     'all',
      created_at: Time.now.to_s
    )
  end

  def initialize(args)
    @version    = args[:version]
    @locale     = args[:locale]
    @created_at = Time.parse(args[:created_at])
  end

  def current_locale?
    I18n.locale.to_s == @locale || @locale == 'all'
  end

  def current?
    I18n.backend.release == @version
  end
end
