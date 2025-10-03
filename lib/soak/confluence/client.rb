require 'faraday'
require 'json'

module Soak
  module Confluence
    class Client
      def initialize(host, username, api_token)
        @host = host
        @username = username
        @api_token = api_token
      end

      def get(path, params = {})
        response = connection.get(path, params)
        JSON.parse(response.body) if response.success?
      end

      private

      def connection
        @connection ||= Faraday.new(url: "https://#{@host}") do |faraday|
          faraday.request :authorization, :basic, @username, @api_token
          faraday.adapter Faraday.default_adapter
        end
      end
    end
  end
end
