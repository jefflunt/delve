require 'thor'
require_relative 'crawlers/spider'
require_relative 'crawlers/spider_domain'
require_relative 'crawlers/spider_path'
require_relative 'confluence/publisher'

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
      crawler = Delve::Crawlers::Spider.new(url, depth.to_i)
      crawler.crawl
    end

    desc "crawl-domain <url> [depth]", "crawl a url within its domain"
    def crawl_domain(url, depth = 2)
      crawler = Delve::Crawlers::SpiderDomain.new(url, depth.to_i)
      crawler.crawl
    end

    desc "crawl-path <url> [depth]", "crawl a url within its path"
    def crawl_path(url, depth = 2)
      crawler = Delve::Crawlers::SpiderPath.new(url, depth.to_i)
      crawler.crawl
    end

    desc "confluence-publish <host> <directory> <root_page_id>", "publish a directory of markdown to confluence"
    def confluence_publish(host, directory, root_page_id)
      publisher = Delve::Confluence::Publisher.new(host, directory, root_page_id)
      publisher.publish
    end
  end
end
