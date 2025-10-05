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

        content, status, rep = _fetch_content(page_id)
        links = []
        attachments = []
        if status == 200 && content
          links.concat(_fetch_child_links(page_id))
          links.concat(_extract_inline_links(content))
          links.concat(_extract_storage_page_refs(page_id))
          links.uniq!
          attachments = _fetch_all_attachments(page_id)
        end
        # optional pretty_raw formatting (basic newline insertion after block tags)
        if content && @config['pretty_raw'] && @config['pretty_raw'] =~ /^(1|true|yes|on)$/i
          content = content.gsub(/<(\/)?(p|div|h[1-6]|ul|ol|li|table|thead|tbody|tr|td|th|pre|blockquote)>/i) { |m| "#{m}\n" }
        end
        # log representation and length for diagnostics
        puts ("confl  rep=#{rep} len=#{content ? content.bytesize : 0} attach=#{attachments.length} #{@uri}") if content
        FetchResult.new(url: @uri.to_s, content: content, links: links, status: status, type: 'confl', attachments: attachments)
      end

      private

      def _extract_page_id
        match = @uri.path.match(/\/pages\/(\d+)/)
        match[1] if match
      end

      def _fetch_all_attachments(page_id)
        start = 0
        acc = []
        loop do
          response = @client.get("/wiki/rest/api/content/#{page_id}/child/attachment", { limit: 50, start: start })
          break unless response && response['results']
          response['results'].each do |att|
            acc << {
              'id' => att['id'],
              'title' => att['title'],
              'mediaType' => att.dig('metadata', 'mediaType'),
              'download' => att.dig('_links', 'download') ? "https://#{@uri.host}#{att.dig('_links', 'download')}" : nil,
              'size' => att.dig('extensions', 'fileSize')
            }
          end
          size = response['size'] || response['results'].length
            limit = response['limit'] || 50
          start_val = response['start'] || start
          total = response['totalSize'] || response['size']
          break if total && (start_val + size) >= total
          start = start_val + size
        end
        acc
      end

      # extract Confluence storage page refs (ac:link / ri:page)
      # attempts to resolve by content-id; falls back to title+space search
      def _extract_storage_page_refs(page_id)
        storage_response = @client.get("/wiki/rest/api/content/#{page_id}", expand: 'body.storage')
        return [] unless storage_response && storage_response['body'] && storage_response['body']['storage']
        storage_html = storage_response['body']['storage']['value']
        doc = Nokogiri::HTML(storage_html)
        links = []
        doc.css('ac\:link ri\:page, ri\:page').each do |node|
          cid = node['ri:content-id'] || node['ri:resource-id']
          if cid
            links << @uri.to_s.gsub(/\/pages\/\d+/, "/pages/#{cid}")
            next
          end
          title = node['ri:content-title']
          next unless title
          space_key = @config['space_key']
          next unless space_key
          begin
            search = @client.get('/wiki/rest/api/content', { title: title, spaceKey: space_key, limit: 1 })
            if search && search['results'] && search['results'][0]
              scid = search['results'][0]['id']
              links << @uri.to_s.gsub(/\/pages\/\d+/, "/pages/#{scid}") if scid
            end
          rescue StandardError
            next
          end
        end
        links.uniq
      end

      def _fetch_content(page_id)
        response = @client.get("/wiki/rest/api/content/#{page_id}", expand: 'body.export_view,body.view,body.storage')
        return [nil, @client.last_status || 0, nil] unless response && response['body']
        body = response['body']
        export_v = body.dig('export_view', 'value') if body['export_view']
        view_v = body.dig('view', 'value') if body['view']
        storage_v = body.dig('storage', 'value') if body['storage']
        # choose best representation: prefer export_view unless it's too small compared to storage
        chosen = export_v
        rep = 'export_view'
        if storage_v && export_v && export_v.bytesize < (storage_v.bytesize * 0.7)
          chosen = storage_v
          rep = 'storage'
        end
        if !chosen
          if view_v
            chosen = view_v
            rep = 'view'
          elsif storage_v
            chosen = storage_v
            rep = 'storage'
          end
        end
        [chosen, @client.last_status, rep]
      end

      def _fetch_child_links(page_id)
        start = 0
        acc = []
        loop do
          response = @client.get("/wiki/rest/api/content/#{page_id}/child/page", { limit: 50, start: start })
          break unless response && response['results']
          response['results'].each do |page|
            acc << "https://#{@uri.host}#{@uri.path.gsub(/\/pages\/\d+/, "/pages/#{page['id']}")}" 
          end
          size = response['size'] || response['results'].length
          limit = response['limit'] || 50
          start_val = response['start'] || start
          total = response['totalSize'] || response['size']
          break if total && (start_val + size) >= total
          start = start_val + size
        end
        acc
      end

      def _extract_inline_links(html)
        doc = Nokogiri::HTML(html)
        base = "https://#{@uri.host}"
        links = []

        doc.css('a[href]').each do |a|
          href = a['href']
          next if href.nil? || href.empty?
          begin
            uri = URI.parse(href)
            uri = URI.join(base, href) if uri.relative?
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
