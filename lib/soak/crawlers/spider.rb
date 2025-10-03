require_relative 'fetcher'
require_relative 'cleaner'
require_relative 'saver'
require 'set'

module Soak
  # given a starting url, crowls outward upto the maximum specified depth
  class Spider
    def initialize(start_url, depth = 2)
      @start_url = start_url
      @depth = depth
      @queue = Queue.new
      @visited = Set.new
    end

    def crawl
      @queue << [@start_url, 0]
      @visited << @start_url

      while !@queue.empty?
        url, current_depth = @queue.pop
        next if current_depth > @depth

        html = Fetcher.fetch(url)
        next unless html

        cleaner = Cleaner.new(html, url)
        saver = Saver.new(cleaner.markdown, url)
        saver.save

        puts "saved #{url}"

        if current_depth < @depth
          cleaner.links.each do |link|
            next if @visited.include?(link)
            @visited << link
            @queue << [link, current_depth + 1]
          end
        end
      end
    end
  end
end
