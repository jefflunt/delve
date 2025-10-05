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
        content, links, status = confluence_fetcher.content_and_links
        [content, links, status, 'confl']
      else
        body, status = Html::Fetcher.fetch(url)
        [body, nil, status, 'web'] # links nil so spider extracts
      end
    end

    def self._load_config
      Delve::Config.load
    end
  end
end
