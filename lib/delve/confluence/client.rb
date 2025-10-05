require 'faraday'
require 'json'
require 'uri'

module Delve
  module Confluence
    class Client
      def initialize(host, username, api_token)
        @host = host
        @username = username
        @api_token = api_token
      end

      def get(path, params = {})
        response = connection.get(path, params) do |req|
          _debug_request('GET', path, params, req.headers)
        end
        JSON.parse(response.body) if response.success?
      end

      def post(path, body)
        response = connection.post(path) do |req|
          req.headers['Content-Type'] = 'application/json'
          req.body = body.to_json
          _debug_request('POST', path, nil, req.headers)
        end
        JSON.parse(response.body) if response.success?
      end

      def put(path, body)
        response = connection.put(path) do |req|
          req.headers['Content-Type'] = 'application/json'
            req.body = body.to_json
          _debug_request('PUT', path, nil, req.headers)
        end
        JSON.parse(response.body) if response.success?
      end

      def find_page_by_title(title, parent_id)
        # Confluence API doesn't let you search by parent AND title in one go,
        # so we get all children and filter manually.
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
          faraday.request :authorization, :basic, @username, @api_token
          faraday.headers['Accept'] = 'application/json'
          faraday.adapter Faraday.default_adapter
        end
      end

      def _debug_request(verb, path, params, headers)
        query = params && !params.empty? ? "?#{URI.encode_www_form(params)}" : ''
        full = "https://#{@host}#{path}#{query}"
        sanitized = _sanitize_headers(headers)
        puts "[delve confluence debug] #{verb} #{full}\n  headers: #{sanitized.inspect}"
      rescue => e
        warn "debug logging failed: #{e.message}"
      end

      def _sanitize_headers(headers)
        return {} unless headers
        headers.each_with_object({}) do |(k, v), acc|
          if k.downcase == 'authorization' && v&.start_with?('Basic ')
            token = v.split(' ', 2)[1]
            acc[k] = "Basic #{token[0,8]}..." # truncate for safety
          else
            acc[k] = v
          end
        end
      end
    end
  end
end
