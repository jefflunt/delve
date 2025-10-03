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
        html_content = Readability::Document.new(
          @html,
          tags: %w[div p a h1 h2 h3 h4 h5 h6 em strong code pre blockquote ul ol li],
          attributes: %w[href]
        ).content
        doc = Nokogiri::HTML(html_content)
        base_uri = URI.parse(@url)

        doc.css('a').each do |a|
          href = a['href']
          next if href.nil? || href.empty?

          uri = URI.parse(href)
          a['href'] = base_uri.merge(uri).to_s if uri.relative?
        end

        doc.to_html
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
