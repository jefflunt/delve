require_relative 'html/fetcher'
require_relative 'confluence/fetcher'
require_relative 'config'

module Delve
  class Fetcher
    def self.fetch(url)
       config = Delve::Config.confluence_config
      uri = URI.parse(url)

      if config[uri.host]
        confluence_fetcher = Confluence::Fetcher.new(url, Delve::Config.confluence_config)
        confluence_fetcher.content_and_links
      else
        html = Html::Fetcher.fetch(url)
        [html, nil] # Return nil for links, as the crawler will extract them
      end
    end

    def self._load_config
      Delve::Config.load
    end
  end
end
