require_relative '../log/logger'
require_relative './heroku-description'
require 'json'
require 'platform-api'
require 'pp'

module CsBuilder

  module Heroku

    # See: https://devcenter.heroku.com/articles/platform-api-deploying-slugs
    class HerokuDeployer

      def initialize()
        @log = CsBuilder::Log.get_logger('heroku-deployer')
        @heroku = PlatformAPI.connect_oauth(auth_token)
      end

      def deploy(slug, process_hash, app, commit_hash, description, stack, force: false)

        raise "Can't deploy - slug doesn't exist" unless File.exists? slug

        if(already_deployed(app, commit_hash, description) and !force)
          @log.warn("The app: '#{app}', already has this version: '#{commit_hash}', #{description} deployed, and force is set to #{force} - skipping")
          nil
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


      def already_deployed(app, commit_hash, description)

        new_desc = HerokuDescription.from_json_string(description) 
        
        if(new_desc.nil?)
          @log.warn("The description #{description} can't be read as a HerokuDescription")
        end

        current_desc = get_current_description(app)

        @log.debug("current_desc: #{current_desc}, #{current_desc.class.name}")
        @log.debug("new_desc: #{new_desc}, #{new_desc.class.name}")

        if(current_desc.nil? and new_desc.nil?)
          false
        else
          current_desc == new_desc
        end
      end
      
      private

      def get_current_description(app)
        release = get_most_recent_release(app)
        slug_id = release["slug"]["id"]
        slug_info = @heroku.slug.info(app, slug_id)
        @log.debug("slug: \n#{PP.pp(slug_info, "")}")
        HerokuDescription.from_json_string(slug_info["commit_description"])
      end

      def nilify(s)
        s.nil? ? s : s.empty? ? nil : s
      end

      def get_current_commit_hash(app)
        release = get_most_recent_release(app)
        @log.debug("app: #{app}, release: #{release}")

        if release.nil?
          ""
        else
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
        begin
          @heroku.release.create(app, {"slug" => id})
        rescue => e 
          @log.error("#{__method__}: app: #{app}, id: #{id} - failed...")
          @log.error(e)
          raise e
        end
      end

      def auth_token
         (ENV["HEROKU_AUTH_TOKEN"] || `heroku auth:token`).chomp
      end

    end

  end

end
