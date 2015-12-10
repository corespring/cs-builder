require_relative '../log/logger'
require 'json'
require 'platform-api'
require 'pp'

module CsBuilder

  module Heroku

    # See: https://devcenter.heroku.com/articles/platform-api-deploying-slugs
    class HerokuDeployer

      def initialize(options: {})
        @log = CsBuilder::Log.get_logger('heroku-deployer')
        @options = options
        @heroku = PlatformAPI.connect_oauth(auth_token)
      end


      def deploy(slug, process_hash, app, commit_hash, description, stack, force: false)

        raise "Can't deploy - slug doesn't exist" unless File.exists? slug

        current_commit_hash = nilify(get_current_commit_hash(app))
        new_hash = nilify(commit_hash)
        @log.info("current: #{current_commit_hash}, commit_hash: #{new_hash}, force: #{force}")

        if(current_commit_hash == new_hash and !force)
          @log.warn("The app already has this version #{new_hash} deployed, and force is set to #{force} - skipping")
        else
          create_slug_response = create_slug(app, process_hash, commit_hash, description, stack)
          @log.debug("create_slug_response: #{create_slug_response}")
          blob_url = create_slug_response["blob"]["url"]
          release_id = create_slug_response["id"]
          @log.debug "blob_url: #{blob_url}, release_id: #{release_id}"
          put_slug_to_heroku(slug, blob_url)
          release_response = trigger_release(app, release_id)
          @log.debug "release successful for #{app} response: #{release_response}"
          release_response
        end
      end

      private

      def nilify(s)
        s.nil? ? s : s.empty? ? nil : s
      end

      def get_current_commit_hash(app)
        release = get_most_recent_release(app)
        @log.debug("app: #{app}, release: #{release}")

        if release.nil?
          ""
        else
          # @log.debug("release: #{release}")
          slug_id = release["slug"]["id"]
          slug_info = @heroku.slug.info(app,slug_id)
          @log.debug("slug: \n#{PP.pp(slug_info, "")}")
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
          @log.warn(e)
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

        @heroku.slug.create(app, data)
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
        @heroku.release.create(app, {"slug" => id})
      end

      def auth_token
         (ENV["HEROKU_AUTH_TOKEN"] || `heroku auth:token`).chomp
      end

    end

  end

end
