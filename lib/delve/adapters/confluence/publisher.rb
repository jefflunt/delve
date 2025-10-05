require_relative 'client'
require_relative 'markdown_converter'
require_relative '../../config'

module Delve
  module Confluence
    class Publisher
      def initialize(host, directory, root_page_id)
        @host = host
        @directory = directory
        @root_page_id = root_page_id
        @config = _config_for_host
        @client = Client.new(host, @config['username'], @config['api_token'])
      end

      def publish
        _publish_directory(@directory, @root_page_id)
      end

      private

      def _publish_directory(dir, parent_id)
        Dir.glob(File.join(dir, '*')).each do |path|
          if File.directory?(path)
            # For a directory, create a parent page and recurse
            title = File.basename(path).gsub('_', ' ').capitalize
            puts "creating/updating parent page: #{title}"
            page = _create_or_update_page(title, "sub-pages for #{title}", parent_id)
            _publish_directory(path, page['id']) if page
          elsif File.extname(path) == '.md'
            # For a markdown file, publish it
            title = File.basename(path, '.md').gsub('_', ' ').capitalize
            puts "publishing: #{title}"
            content = File.read(path)
            html = MarkdownConverter.to_html(content)
            _create_or_update_page(title, html, parent_id)
          end
        end
      end

      def _create_or_update_page(title, content, parent_id)
        existing_page = @client.find_page_by_title(title, parent_id)

        if existing_page
          new_version = existing_page['version']['number'] + 1
          @client.update_page(existing_page['id'], title, content, new_version)
        else
          @client.create_page(title, content, parent_id, @config['space_key'])
        end
      end

      def _config_for_host
        Delve::Config.confluence_host(@host) || {}
      end
    end
  end
end
