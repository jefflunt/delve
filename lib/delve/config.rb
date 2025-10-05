require 'yaml'
require 'erb'

module Delve
  class Config
    def self.load
      @config ||= begin
                    path = File.expand_path('../../config/delve.yml', __dir__)
                    if File.exist?(path)
                      puts "config found at `#{path}'"
                      raw = File.read(path)
                       erb = ERB.new(raw).result
                       YAML.safe_load(erb, permitted_classes: [], permitted_symbols: [], aliases: false)
                    else
                      puts "config NOT found"
                      {}
                    end
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
