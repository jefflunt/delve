require_relative 'html/fetcher'
require_relative 'confluence/fetcher'
require_relative 'config'

module Delve
  class Fetcher
    def self.fetch(url)
      config = Delve::Config.load
      uri = URI.parse(url)

      if config['confluence'] && config['confluence'][uri.host]
        confluence_fetcher = Confluence::Fetcher.new(url, config['confluence'])
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
