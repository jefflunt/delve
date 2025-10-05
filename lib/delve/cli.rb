require 'thor'
require_relative 'spider'

require_relative 'adapters/confluence/publisher'
require_relative 'publisher'

module Delve
  class CLI < Thor
    desc "delve <url> [depth]", "delve into a url for content"
    def self.exit_on_failure?
      true
    end

    def self.start(args)
      commands = self.all_commands.keys
      if args.first && !commands.include?(args.first.gsub('-', '_')) && args.first !~ /^-/
        args.unshift('crawl')
      end
      super
    end

    desc "crawl <url> [depth]", "crawl a url in all directions"
    def crawl(url, depth = 2)
      crawler = Delve::Spider.new(url, depth.to_i, :all)
      crawler.crawl
    end

    desc "crawl-domain <url> [depth]", "crawl a url within its domain"
    def crawl_domain(url, depth = 2)
      crawler = Delve::Spider.new(url, depth.to_i, :domain)
      crawler.crawl
    end

    desc "crawl-path <url> [depth]", "crawl a url within its path"
    def crawl_path(url, depth = 2)
      crawler = Delve::Spider.new(url, depth.to_i, :path)
      crawler.crawl
    end

    desc "publish <host> <local folder> <parent page id>", "publish a local folder of markdown to a supported destination"
    def publish(host, directory, root_page_id)
      publisher = Delve::Publisher.new(host, directory, root_page_id)
      publisher.publish
    end

    desc "config-validate", "validate config/delve.yml and report errors"
    def config_validate
      require_relative 'config'
      Delve::Config.reload!
      puts 'config valid'
    end
  end
end
