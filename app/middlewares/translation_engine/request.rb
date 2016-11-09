module TranslationEngine
  module Request
    def remote_ip(env)
      request(env).ip
    end

    private

    def request(env)
      Rack::Request.new(env)
    end
  end
end
