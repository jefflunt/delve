require_relative 'html/fetcher'
require_relative 'confluence/fetcher'
require_relative 'config'
require_relative 'fetch_result'

module Delve
  class Fetcher
    def self.fetch(url)
       config = Delve::Config.confluence_config
      uri = URI.parse(url)

      if config[uri.host]
        Confluence::Fetcher.new(url, Delve::Config.confluence_config).fetch_result
      else
        Html::Fetcher.fetch(url)
      end
    end

    def self._load_config
      Delve::Config.load
    end
  end
end
