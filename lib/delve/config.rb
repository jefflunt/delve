require 'yaml'

module Delve
  class Config
    def self.load
      @config ||= begin
        path = File.expand_path('../config/delve.yml', __dir__)
        File.exist?(path) ? YAML.load_file(path) : {}
      end
    end

    def self.reload!
      @config = nil
      load
    end

    def self.confluence_config
      load['confluence'] || {}
    end

    def self.confluence_host(host)
      confluence_config[host]
    end
  end
end
