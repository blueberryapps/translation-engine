class Translation

  def self.catched
    @catched ||= []
  end

  def self.clear_catched
    @catched = []
  end

  def self.catch(text, keys)
    catched << {
      data_type: data_type(text),
      key:       keys.join('.'),
      text:      normalize_for_translation_server(text)
    }
  end

  def self.normalize_for_translation_server(value)
    if value.is_a?(Hash) || value.is_a?(Array) || value.is_a?(Symbol)
      YAML.dump(value).gsub("---\n", '')
    else
      value
    end
  end

  def self.data_type(text)
    case text
    when Array   then 'array'
    when String  then 'string'
    when Float   then 'float'
    when Integer then 'integer'
    else nil
    end
  end

  def initialize(text, keys)
    @text = text
    @keys = keys
    self.class.catch(@text, @keys)
  end

  def full_key
    @keys.join('.') rescue ''
  end

  def to_s
    if TranslationEngine.use_screenshots
      "--TRANSLATION--#{full_key}--#{@text}"
    else
      @text
    end
  end
end
