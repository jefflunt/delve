require_relative 'client'

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
        links = status == 200 ? _fetch_child_links(page_id) : []
        FetchResult.new(url: @uri.to_s, content: content, links: links, status: status, type: 'confl')
      end

      private

      def _extract_page_id
        match = @uri.path.match(/\/pages\/(\d+)/)
        match[1] if match
      end

      def _fetch_content(page_id)
        response = @client.get("/wiki/rest/api/content/#{page_id}", expand: 'body.storage')
        if response
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
    end
  end
end


      def fetch_result
        page_id = _extract_page_id
        return FetchResult.new(url: @uri.to_s, content: nil, links: [], status: 0, type: 'confl') unless page_id

        content, status = _fetch_content(page_id)
        links = status == 200 ? _fetch_child_links(page_id) : []
        FetchResult.new(url: @uri.to_s, content: content, links: links, status: status, type: 'confl')
      end

      private

      def _extract_page_id
        # Confluence URLs can have different formats, this is a common one.
        # e.g., /wiki/spaces/SPACE/pages/12345/Page+Title
        match = @uri.path.match(/\/pages\/(\d+)/)
        match[1] if match
      end

      def _fetch_content(page_id)
        # 'body.storage.value' gives us the raw HTML content of the page
        response = @client.get("/wiki/rest/api/content/#{page_id}", expand: 'body.storage')
        if response
          [response['body']['storage']['value'], @client.last_status]
        else
          [nil, @client.last_status || 0]
        end
      end

      def _fetch_child_links(page_id)
        # This gets the direct children of the current page
        response = @client.get("/wiki/rest/api/content/#{page_id}/child/page")
        return [] unless response && response['results']

        response['results'].map do |page|
          "https://#{@uri.host}#{@uri.path.gsub(/\/pages\/\d+/, "/pages/#{page['id']}")}"
        end
      end
    end
  end
end
