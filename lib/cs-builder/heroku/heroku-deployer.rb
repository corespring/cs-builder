require 'rest-client'
require 'base64'
require_relative '../log/logger'
require 'json'
require 'platform-api'

module CsBuilder

  module Heroku

    # See: https://devcenter.heroku.com/articles/platform-api-deploying-slugs
    class HerokuDeployer

      def initialize
        @log = CsBuilder::Log.get_logger('heroku-deployer')

        @headers = {
          "Accept" =>  "application/vnd.heroku+json; version=3" ,
          "Authorization" => "Bearer: #{auth_key}",
          :content_type => :json
        }

        # TODO: Move everything over to the new heroku api client
        @heroku = PlatformAPI.connect_oauth(auth_key)

      end

      def deploy(slug, process_hash, app, commit_hash, description, stack, force: false)

        raise "Can't deploy - slug doesn't exist" unless File.exists? slug

        if(get_current_commit_hash(app) == commit_hash and !force)
          @log.warn("The app already has this version #{version} deployed - skipping")
        else
          create_slug_response = create_slug(app, process_hash, commit_hash, description, stack)
          @log.debug("response: #{create_slug_response}")
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
      end

      private

      def get_current_commit_hash(app)
        release = get_most_recent_release(app)
        @log.debug("app: #{app}, release: #{release}")

        if release.nil?
          ""
        else
          @log.debug("release: #{release}")
          slug_id = release["slug"]["id"]
          slug_info = heroku.slug.info(app,slug_id)
          @log.debug("slug: #{slug_info.pretty_inspect}")
          slug_info["commit"] 
        end
      end

      def get_most_recent_release(app)
        @log.debug("get release list...")
        begin
          release_list = @heroku.release.list(app)
          sorted = release_list.sort{ |o| o["version"]}
          sorted[0] if sorted.length > 0
        rescue => e
          @log.warn(e.response.body)
          raise e
        end
      end

      def create_slug(app, processes, commit_hash, description, stack)

        @log.debug(processes)

        data = {
          :process_types => processes,
          :commit => commit_hash,
          :commit_description => description, 
          :stack => stack
        }

        begin
          RestClient::Request.execute(
            :method => :post,
            :payload => data,
            :url => slugs_url(app),
            :headers => @headers,
            :timeout => 3)
        rescue => e
          @log.warn e.response
          raise e
        end

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
        auth_token = (ENV["HEROKU_AUTH_TOKEN"] || `heroku auth:token`).chomp
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
