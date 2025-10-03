require 'thor'
require_relative 'crawlers/spider'

module Soak
  class CLI < Thor
    desc "soak <url> [depth]", "soak up a url for content"
    def self.exit_on_failure?
      true
    end

    def self.start(args)
      # if the first argument is not a thor command, assume it's a url
      # and prepend the default command.
      if args.first && !self.respond_to?(args.first)
        args.unshift('crawl')
      end
      super
    end

    desc "crawl <url> [depth]", "crawl a url in all directions"
    def crawl(url, depth = 2)
      crawler = Soak::Crawlers::Spider.new(url, depth.to_i)
      crawler.crawl
    end
  end
end
