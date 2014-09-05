require 'rest-client'
require 'base64'
require 'log4r'
require 'log4r/outputter/datefileoutputter'
require 'json'

module CsBuilder

  module Heroku

    # See: https://devcenter.heroku.com/articles/platform-api-deploying-slugs
    class HerokuDeployer

      Log4r.define_levels(*Log4r::Log4rConfig::LogLevels)

      def initialize
        @log = Log4r::Logger.new('heroku-deployer')
        @log.outputters << Log4r::StdoutOutputter.new('log_stdout') #, :level => Log4r::WARN )
        @log.level = Log4r::DEBUG

        @headers = {
          "Accept" =>  "application/vnd.heroku+json; version=3" ,
          "Authorization" => auth_key,
          :content_type => :json
        }
      end

      def deploy(slug, process_hash, app)

        raise "Can't deploy - slug doesn't exist" unless File.exists? slug

        create_slug_response = create_slug(app, process_hash)
        result = JSON.parse(create_slug_response)
        blob_url = result["blob"]["url"]
        release_id = result["id"]
        @log.debug "blob url: #{blob_url}"
        @log.debug "id: #{release_id}"
        put_slug_to_heroku(slug, blob_url)
        release_response = trigger_release(app, release_id)
        @log.debug "release successful for #{app} response: #{release_response}"
        release_response
      end

      private
      def create_slug(app, processes)

        @log.debug(processes)

        data = {
          :process_types => processes
        }

        RestClient::Request.execute(
          :method => :post,
          :payload => data,
          :url => slugs_url(app),
          :headers => @headers,
        :timeout => 3)
      end

      #TODO - use a ruby lib instead
      def put_slug_to_heroku(slug, url)
        cmd = <<-EOF
        curl -X PUT \
          -H "Content-Type:" \
          --data-binary @#{slug} \
          "#{url}"
        EOF
        `#{cmd}`
      end

      def trigger_release(app, id)
        RestClient::Request.execute(
          :method => :post,
          :payload => "{\"slug\": \"#{id}\"}",
          :url => releases_url(app),
          :headers => @headers,
          :timeout => 3
        )
      end

      def auth_key
        auth_token = ENV["HEROKU_AUTH_TOKEN"] || `heroku auth:token`
        @log.debug "Found an auth token" unless auth_token.nil?
        raise "No auth token - You need to login to the heroku toolbelt" if auth_token.nil? or auth_token.empty?
        Base64.encode64(":#{auth_token}")
      end

      def slugs_url(app)
        "https://api.heroku.com/apps/#{app}/slugs"
      end

      def releases_url(app)
        "https://api.heroku.com/apps/#{app}/releases"
      end

    end

  end

end
