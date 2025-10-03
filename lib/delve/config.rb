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
  end
end
