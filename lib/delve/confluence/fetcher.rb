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

      def content_and_links
        page_id = _extract_page_id
        return [nil, []] unless page_id

        content = _fetch_content(page_id)
        links = _fetch_child_links(page_id)

        [content, links]
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
        response['body']['storage']['value'] if response
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
