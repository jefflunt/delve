require_relative 'confluence/publisher'
require_relative 'config'

module Delve
  class Publisher
    def initialize(host, directory, root_page_id)
      @host = host
      @directory = directory
      @root_page_id = root_page_id
       @config = Delve::Config.confluence_config
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
      Delve::Config.confluence_host(@host)
    end

    def _load_config
      Delve::Config.load
    end # retained for compatibility; may remove later
  end
end
