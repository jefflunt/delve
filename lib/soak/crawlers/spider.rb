require_relative '../fetcher'
require_relative '../html/cleaner'
require_relative '../saver'
require 'set'

module Soak
  module Crawlers
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

          content, links = Soak::Fetcher.fetch(url)
          next unless content

          cleaner = Soak::Html::Cleaner.new(content, url)
          saver = Soak::Saver.new(cleaner.markdown, url)
          saver.save

          puts "saved #{url}"

          if current_depth < @depth
            links ||= cleaner.links
            links.each do |link|
              next if @visited.include?(link)
              @visited << link
              @queue << [link, current_depth + 1]
            end
          end
        end
      end
    end
  end
end
