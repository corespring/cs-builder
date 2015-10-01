require_relative '../models/paths'
require_relative '../io/safe-file-removal'

require 'yaml'

module CsBuilder
  module Commands

    class CleanRepos < CoreCommand

      include Models
      include Io::SafeFileRemoval      

      def initialize(level, config_dir, days)
        @days = days
        super('clean_repos', level, config_dir)
      end

      def run(options)
        path_repos = @config_dir"/repos"
        path_slugs = @config_dir"/slugs"

        @log.debug "path_repos -> @config_dir/#{path_repos}"
        @log.debug "path_slugs -> #{path_slugs}"


      end
      def get_org_dirs(path)
        Dir["#{path}/*"].each{ |f|
          @log.debug("org: #{f}")
        }
      end

      def get_path_date(path)
        return 2
      end
      
      def cleanup(clean_up, path)
        safely_remove(path) if clean_up
      end

    end
  end
end
