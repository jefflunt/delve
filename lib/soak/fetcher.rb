require 'faraday'
require 'faraday/follow_redirects'

module Soak
  class Fetcher
    def self.fetch(url)
      response = _faraday.get(url)
      response.body if response.success?
    rescue Faraday::Error => e
      warn "error fetching #{url}: #{e.message}"
      nil
    end

    def self._faraday
      Faraday.new do |faraday|
        faraday.use Faraday::FollowRedirects::Middleware
        faraday.adapter Faraday.default_adapter
      end
    end
  end
end
