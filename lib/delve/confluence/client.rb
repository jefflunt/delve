require 'faraday'
require 'json'
require 'base64'

module Delve
  module Confluence
    class Client
      def initialize(host, username, api_token)
        @host = host
        @username = username.strip
        @api_token = api_token.strip
      end

      def get(path, params = {})
        response = connection.get(path, params)
        JSON.parse(response.body) if response.success?
      end

      def post(path, body)
        response = connection.post(path) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = body.to_json
        end
        JSON.parse(response.body) if response.success?
      end

      def put(path, body)
        response = connection.put(path) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = body.to_json
        end
        JSON.parse(response.body) if response.success?
      end

      def find_page_by_title(title, parent_id)
        children = get("/wiki/rest/api/content/#{parent_id}/child/page")
        children['results'].find { |p| p['title'] == title } if children && children['results']
      end

      def create_page(title, content, parent_id, space_key)
        post('/wiki/rest/api/content', {
          type: 'page',
          title: title,
          ancestors: [{ id: parent_id }],
          space: { key: space_key },
          body: {
            storage: {
              value: content,
              representation: 'storage'
            }
          }
        })
      end

      def update_page(page_id, title, content, new_version)
        put("/wiki/rest/api/content/#{page_id}", {
          type: 'page',
          title: title,
          version: { number: new_version },
          body: {
            storage: {
              value: content,
              representation: 'storage'
            }
          }
        })
      end

      private

      def connection
        @connection ||= Faraday.new(url: "https://#{@host}") do |faraday|
          faraday.headers['Authorization'] = _auth_header
          faraday.headers['Accept'] = 'application/json'
          faraday.adapter Faraday.default_adapter
        end
      end

      def _auth_header
        token = Base64.strict_encode64("#{@username}:#{@api_token}")
        "Basic #{token}"
      end
    end
  end
end
