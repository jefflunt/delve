require 'fileutils'
require 'uri'

module Delve
  class Saver
    def initialize(markdown, url, output_dir = 'content')
      @markdown = markdown
      @url = url
      @output_dir = output_dir
    end

    def save
      FileUtils.mkdir_p(File.dirname(file_path))
      File.write(file_path, @markdown)
    end

    def file_path
      uri = URI.parse(@url)
      path = uri.path
      path = '/index' if path.empty? || path == '/'

      file_name = File.basename(path, '.*') + '.md'
      File.join(@output_dir, uri.host, File.dirname(path), file_name)
    end
  end
end
