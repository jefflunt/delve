require 'thor'
require_relative 'crawler'

module Soak
  class CLI < Thor
    desc "crawl URL [DEPTH]", "crawl a website starting at URL to a given DEPTH"
    def crawl(url, depth = 2)
      crawler = Crawler.new(url, depth.to_i)
      crawler.crawl
    end
  end
end
