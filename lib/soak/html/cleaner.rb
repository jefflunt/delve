require 'nokogiri'
require 'readability'
require 'reverse_markdown'
require 'uri'

module Soak
  module Html
    class Cleaner
      def initialize(html, url)
        @html = html
        @url = url
        @doc = Nokogiri::HTML(html)
      end

      def markdown
        ReverseMarkdown.convert(content)
      end

      def content
        Readability::Document.new(@html).content
      end

      def links
        base_uri = URI.parse(@url)
        @doc.css('a').map do |a|
          href = a['href']
          next if href.nil? || href.empty?

          uri = URI.parse(href)
          if uri.relative?
            uri = base_uri.merge(uri)
          end

          uri.to_s if uri.host == base_uri.host
        end.compact.uniq
      end
    end
  end
end
