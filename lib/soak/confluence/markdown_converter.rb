require 'kramdown'

module Soak
  module Confluence
    class MarkdownConverter
      def self.to_html(markdown)
        Kramdown::Document.new(markdown).to_html
      end
    end
  end
end
