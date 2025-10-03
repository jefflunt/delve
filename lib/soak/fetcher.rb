require 'yaml'
require_relative 'html/fetcher'
require_relative 'confluence/fetcher'

module Soak
  class Fetcher
    def self.fetch(url)
      config = _load_config
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
      config_path = File.expand_path('../../config/soak.yml', __dir__)
      File.exist?(config_path) ? YAML.load_file(config_path) : {}
    end
  end
end
