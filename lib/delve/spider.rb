require_relative 'fetcher'
require_relative 'fetch_logger'
require_relative 'html/cleaner'
require_relative 'saver'
require 'set'
require 'uri'

module Delve
  class Spider
    def initialize(start_url, depth = 2, filter = :all)
      @start_url = start_url
      @depth = depth
      @filter = filter
      @queue = Queue.new
      @visited = Set.new
      _init_filter
    end

    def crawl
      @queue << [@start_url, 0]
      @visited << @start_url

      while !@queue.empty?
        url, current_depth = @queue.pop
        next if current_depth > @depth

        result = Delve::Fetcher.fetch(url)

        Delve::FetchLogger.log(result)

        next unless result.content

        cleaner = Delve::Html::Cleaner.new(result.content, url)
        saver = Delve::Saver.new(cleaner.markdown, url)
        saver.save

        if current_depth < @depth
          links = (result.links && !result.links.empty?) ? result.links : cleaner.links
          links.each do |link|
            next if @visited.include?(link)
            next unless _allow_link?(link)
            @visited << link
            @queue << [link, current_depth + 1]
          end
        end
      end
    end

    def _init_filter
      case @filter
      when :domain
        @domain = _effective_domain(@start_url)
      when :path
        @base_path = URI.parse(@start_url).path
      end
    end

    def _allow_link?(link)
      case @filter
      when :all
        true
      when :domain
        _effective_domain(link) == @domain
      when :path
        begin
          URI.parse(link).path.start_with?(@base_path)
        rescue URI::InvalidURIError
          false
        end
      else
        true
      end
    end

    def _effective_domain(url)
      URI
        .parse(url)
        .host
        .split('.')
        .last(2)
        .join('.')
    rescue URI::InvalidURIError
      nil
    end
  end
end
