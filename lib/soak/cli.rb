require 'thor'
require_relative 'crawler'
require_relative 'plugins/base'

Dir[File.join(__dir__, 'plugins', '*.rb')].each { |file| require file }

module Soak
  class CLI < Thor
    desc "crawl URL [DEPTH]", "crawl a website starting at URL to a given DEPTH"
    def crawl(url, depth = 2)
      crawler = Crawler.new(url, depth.to_i)
      crawler.crawl
    end

    desc "plugin NAME [ARGS...]", "run a plugin"
    def plugin(name, *args)
      plugin_class = Soak::Plugins::Base.plugins[name]
      if plugin_class
        plugin_class.new.run(args)
      else
        puts "plugin '#{name}' not found"
      end
    end
  end
end

