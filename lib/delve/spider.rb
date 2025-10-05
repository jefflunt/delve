require_relative 'fetcher'
require_relative 'fetch_logger'
require_relative 'adapters/html/cleaner'
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

        if result.type == 'confl'
          # save raw rendered html for debugging
          raw_saver = Delve::Saver.new(result.content, url, 'content_raw')
          raw_saver.save

          # basic conversion: reverse_markdown on the rendered html
          converted = ReverseMarkdown.convert(result.content)

            # fallback: if conversion produced no urls but raw html had anchors, append them
          if !converted.include?('http')
            anchors = _extract_confluence_links(result.content)
            unless anchors.empty?
              converted << "\n\nlinks:\n"
              anchors.each do |text, href|
                label = text.strip.empty? ? href : text.strip
                converted << "- [#{label}](#{href})\n"
              end
            end
          end

          saver = Delve::Saver.new(converted, url)
          saver.save
        else
          cleaner = Delve::Html::Cleaner.new(result.content, url)
          saver = Delve::Saver.new(cleaner.markdown, url)
          saver.save
        end

        if current_depth < @depth
          # prefer adapter-provided links; fall back to cleaner links for generic html
          links = if result.links && !result.links.empty?
                    result.links
                  elsif result.type != 'confl'
                    # only defined in the non-confluence branch
                    cleaner.links
                  else
                    []
                  end
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

    def _extract_confluence_links(html)
      require 'nokogiri'
      doc = Nokogiri::HTML(html)
      doc.css('a[href]').map do |a|
        [a.text || '', a['href']]
      end.select { |(_, href)| href && href.start_with?('http') }
    end
  end
end
