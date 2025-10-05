require_relative 'client'
require 'nokogiri'

module Delve
  module Confluence
    class Fetcher
      def initialize(url, config)
        @uri = URI.parse(url)
        @config = config[@uri.host]
        raise "no confluence config for #{@uri.host}" unless @config
        @client = Client.new(@uri.host, @config['username'], @config['api_token'])
      end

      def fetch_result
        page_id = _extract_page_id
        return FetchResult.new(url: @uri.to_s, content: nil, links: [], status: 0, type: 'confl') unless page_id

        content, status = _fetch_content(page_id)
        links = []
        if status == 200 && content
          links.concat(_fetch_child_links(page_id))
          links.concat(_extract_inline_links(content))
          links.uniq!
        end
        FetchResult.new(url: @uri.to_s, content: content, links: links, status: status, type: 'confl')
      end

      private

      def _extract_page_id
        match = @uri.path.match(/\/pages\/(\d+)/)
        match[1] if match
      end

      def _fetch_content(page_id)
        response = @client.get("/wiki/rest/api/content/#{page_id}", expand: 'body.export_view')
        if response && response['body'] && response['body']['export_view']
          [response['body']['export_view']['value'], @client.last_status]
        elsif response && response['body'] && response['body']['storage']
          # fallback: some older instances may not support export_view
            [response['body']['storage']['value'], @client.last_status]
        else
          [nil, @client.last_status || 0]
        end
      end

      def _fetch_child_links(page_id)
        response = @client.get("/wiki/rest/api/content/#{page_id}/child/page")
        return [] unless response && response['results']

        response['results'].map do |page|
          "https://#{@uri.host}#{@uri.path.gsub(/\/pages\/\d+/, "/pages/#{page['id']}")}" 
        end
      end

      def _extract_inline_links(html)
        doc = Nokogiri::HTML(html)
        base = "https://#{@uri.host}"
        links = []

        # standard anchor tags
        doc.css('a[href]').each do |a|
          href = a['href']
          next if href.nil? || href.empty?
          begin
            uri = URI.parse(href)
            if uri.relative?
              uri = URI.join(base, href)
            end
            links << uri.to_s if uri.host == @uri.host
          rescue URI::InvalidURIError
            next
          end
        end

        links
      end
    end
  end
end
