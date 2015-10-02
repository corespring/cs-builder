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
        path_repos = File.join(@config_dir, "repos")
        path_slugs = File.join(@config_dir, "slugs")

        @log.debug "path_repos -> #{path_repos}"
        @log.debug "path_slugs -> #{path_slugs}"

        get_org_dirs(path_repos)
        get_org_dirs(path_slugs)
      end

      def get_org_dirs(path)
        Dir["#{path}/*"].each{ |f|
          #@log.debug("org: #{f}")
          get_projects(f)
        }
      end

      def get_projects(path)
        Dir["#{path}/*"].each{ |f|
          #@log.debug("projects: #{f}")
          get_branches(f)
        }
      end

      def get_branches(path)
        Dir["#{path}/*"].each{ |f|
          #@log.debug("branches: #{f}")
          get_path_date(f)
        }
      end

      def get_path_date(path)
        Dir.glob("#{path}/*/").max_by { |f| 
          time = File.mtime(f) 
          time_now = Time.now
          time_to_compare = Time.at(time_now - @days * 24 * 60 * 60)
          @log.debug("DELETE #{path}, it's more than #{@days} days OLD") if time < time_to_compare
          cleanup(path) if time < time_to_compare
        }
      end
      
      def cleanup(path)
        safely_remove(path)
      end

    end
  end
end
