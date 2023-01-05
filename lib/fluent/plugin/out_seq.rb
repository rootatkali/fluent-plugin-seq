#
# Copyright 2023- Kryon Systems
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

require "fluent/plugin/output"
require "net/http"
require "json"

module Fluent
  module Plugin
    class SeqOutput < Output
      Fluent::Plugin.register_output("seq", self)

      helpers :timer

      LOG_LEVELS = {
        'TRACE' => 'Verbose',
        'DEBUG' => 'Debug',
        'INFO' => 'Information',
        'WARNING' => 'Warning',
        'ERROR' => 'Error',
        'FATAL' => 'Fatal'
      }

      config_param :scheme, :string, default: "http"
      config_param :host, :string
      config_param :port, :integer, default: 5341
      config_param :path, :string, default: nil
      config_param :api_key, :string, secret: true, default: nil
      config_param :default_level, :string, default: 'DEBUG'

      def configure(conf)
        super

        if @scheme == "https" and @port != 443
          log.warn "Scheme is set to https but port is not 443 (port: #{port})"
        end

        host = @host.gsub(/\/$/, '') # remove last '/'

        path = ''
        if @path
          path = @path.gsub(/(^\/)|(\/$)/, '')
        end

        @server_url = "#{@scheme}://#{host}:#{@port}/#{path}"
        @base_api = "#{@server_url}api"
      end

      def start
        super

        uri = URI.parse("#{@server_url}health")

        timer_execute(:health_timer, 60) do
          health = Net::HTTP.get(uri)
          log.debug health
        rescue
          log.error "Cannot connect to Seq server at #{@server_url}"
        end
      end

      def format_event(time, record)
        {
          "Timestamp": Time.at(time).to_s,
          "MessageTemplate": record['MessageTemplate'] || record['message'] || record['msg'] || record['log'] || '(No message provided)',
          "Level": LOG_LEVELS[record['Level'] || record['level'] || @default_level],
          "Exception": record['stack'] || record.dig('err', 'stack') || record['exc_info'] || nil,
          "Properties": record
        }
      end

      def post_events(events)
        api_path = "#{@base_api}\/events\/raw"

        uri = URI.parse(api_path)

        http = Net::HTTP.new(uri.host, uri.port)
        http.use_ssl = @scheme == "https"
        http = http.start

        headers = {'Content-Type' => 'application/json'}
        headers['X-Seq-ApiKey'] = @api_key if @api_key

        req = Net::HTTP::Post.new(uri.path, initheader = headers)
        body = {"Events": events}
        req.body = body.to_json
        res = http.request(req)

        log.debug "#{res.code} #{res.message}"
      rescue Exception
        log.error $!
      end

      def process(tag, es)
        es.each do |time, record|
          for_seq = format_event(time, record)
          post_events([for_seq])
        end
      end

      def write(chunk)
        # Post all events from the chunk at once
        events = []
        chunk.each { |time, record| events.append(format_event(time, record)) }
        post_events(events)
      end
    end
  end
end
