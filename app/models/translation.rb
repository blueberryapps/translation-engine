class Translation

  def self.catched
    @catched ||= []
  end

  def self.clear_catched
    @catched = []
  end

  def self.catch(text, keys)
    if text.is_a?(Hash)
      text.each do |key, value|
        Translation.catch(value, keys + [key])
      end
    else
      catch_basic_value(text, keys)
    end
  end

  def self.catch_basic_value(text, keys)
    catched << {
      data_type: data_type(text),
      key:       keys.join('.'),
      text:      normalize_for_translation_server(text)
    }
  end

  def self.normalize_for_translation_server(value)
    if value.is_a?(Array)
      YAML.dump(value).gsub("---\n", '')
    else
      value
    end
  end

  def self.data_type(text)
    case text
    when Array      then 'array'
    when String     then 'string'
    when Float      then 'float'
    when Integer    then 'integer'
    when TrueClass  then 'boolean'
    when FalseClass then 'boolean'
    when Symbol     then 'symbol'
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
    if TranslationEngine.use_screenshots && @text.is_a?(String)
      "--TRANSLATION--#{full_key}--#{@text}"
    else
      @text
    end
  end
end
