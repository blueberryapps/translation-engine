class Release

  attr_accessor :version, :locale, :created_at

  def initialize(args)
    @version    = args['version']
    @locale     = args['locale']
    @created_at = Time.parse(args['created_at'])
  end

  def current_locale?
    I18n.locale.to_s == @locale
  end
end
