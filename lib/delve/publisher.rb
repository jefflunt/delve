require 'yaml'
require_relative 'confluence/publisher'

module Delve
  class Publisher
    def initialize(host, directory, root_page_id)
      @host = host
      @directory = directory
      @root_page_id = root_page_id
      @config = _load_config
    end

    def publish
      if _confluence_host?
        confluence_publisher = Confluence::Publisher.new(@host, @directory, @root_page_id)
        confluence_publisher.publish
      else
        warn "no publisher configured for #{@host}; skipping (no-op)"
      end
    end

    def _confluence_host?
      @config['confluence'] && @config['confluence'][@host]
    end

    def _load_config
      config_path = File.expand_path('../config/delve.yml', __dir__)
      File.exist?(config_path) ? YAML.load_file(config_path) : {}
    end
  end
end
