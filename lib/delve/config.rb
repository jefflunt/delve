require 'yaml'
require 'erb'

module Delve
  class Config
    SCHEMA = {
      'confluence' => :hash # hash of host => host_config
    }

    CONFLUENCE_HOST_SCHEMA = {
      'username' => :string,
      'api_token' => :string,
      'space_key' => :string,
      'pretty_raw' => :string, # treat as boolean-ish string
      'representations' => :string # comma-separated list
    }

    REQUIRED_TOP_LEVEL = ['confluence']
    REQUIRED_CONFLUENCE_KEYS = ['username', 'api_token'] # space_key optional for read-only

    def self.load
      @config ||= begin
                    path = File.expand_path('../../config/delve.yml', __dir__)
                    if File.exist?(path)
                      raw = File.read(path)
                      erb = ERB.new(raw).result
                      data = YAML.safe_load(erb, permitted_classes: [], permitted_symbols: [], aliases: false) || {}
                      _validate!(data)
                      data
                    else
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

    def self._validate!(data)
      require_relative 'exit_status'

      error_messages = []

      missing = REQUIRED_TOP_LEVEL.reject { |k| data.key?(k) }
      error_messages << "config missing required keys: #{missing.join(', ')}" unless missing.empty?

      unknown_top = data.keys - SCHEMA.keys
      error_messages << "config has unknown top-level keys: #{unknown_top.join(', ')}" unless unknown_top.empty?

      if data.key?('confluence')
        conf = data['confluence']
        unless conf.is_a?(Hash)
          error_messages << 'config key confluence must be a mapping of host -> settings'
        else
          conf.each do |host, host_cfg|
            unless host_cfg.is_a?(Hash)
              error_messages << "confluence host #{host} must map to a hash of settings"
              next
            end

            host_missing = REQUIRED_CONFLUENCE_KEYS.reject { |k| host_cfg.key?(k) }
            unless host_missing.empty?
              error_messages << "confluence host #{host} missing required keys: #{host_missing.join(', ')}"
            end

            unknown = host_cfg.keys - CONFLUENCE_HOST_SCHEMA.keys
            unless unknown.empty?
              error_messages << "confluence host #{host} has unknown keys: #{unknown.join(', ')}"
            end

            CONFLUENCE_HOST_SCHEMA.each do |k, _|
              next unless host_cfg.key?(k)
              v = host_cfg[k]
              unless v.is_a?(String) && !v.strip.empty?
                error_messages << "confluence host #{host} key #{k} must be a non-empty string"
              end
            end
          end
        end
      end

      unless error_messages.empty?
        error_messages.each { |m| warn m }
        exit Delve::ExitStatus::CONFIG_INVALID
      end
    end
  end
end
