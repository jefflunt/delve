require 'faraday'
require 'faraday/follow_redirects'

module Delve
  module Html
    class Fetcher
    def self.fetch(url)
      response = _faraday.get(url)
      content = response.success? ? response.body : nil
      FetchResult.new(url: url, content: content, links: [], status: response.status, type: 'web')
    rescue Faraday::Error => e
      warn "error fetching #{url}: #{e.message}"
      FetchResult.new(url: url, content: nil, links: [], status: 0, type: 'web', error: e)
    end

    def self._faraday
      Faraday.new do |faraday|
        faraday.use Faraday::FollowRedirects::Middleware
        faraday.adapter Faraday.default_adapter
      end
    end
    end
  end
end
