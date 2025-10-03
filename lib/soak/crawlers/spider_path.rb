require_relative '../html/fetcher'
require_relative '../html/cleaner'
require_relative '../saver'
require 'set'
require 'uri'

module Soak
  module Crawlers
    class SpiderPath
      def initialize(start_url, depth = 2)
        @start_url = start_url
        @depth = depth
        @queue = Queue.new
        @visited = Set.new
        @base_path = URI.parse(start_url).path
      end

      def crawl
        @queue << [@start_url, 0]
        @visited << @start_url

        while !@queue.empty?
          url, current_depth = @queue.pop
          next if current_depth > @depth

          html = Soak::Html::Fetcher.fetch(url)
          next unless html

          cleaner = Soak::Html::Cleaner.new(html, url)
          saver = Soak::Saver.new(cleaner.markdown, url)
          saver.save

          puts "saved #{url}"

          if current_depth < @depth
            cleaner.links.each do |link|
              next if @visited.include?(link)
              next unless _in_path?(link)
              @visited << link
              @queue << [link, current_depth + 1]
            end
          end
        end
      end

      def _in_path?(link)
        URI.parse(link).path.start_with?(@base_path)
      rescue URI::InvalidURIError
        false
      end
    end
  end
end
