require_relative '../io/safe-file-removal'

require 'yaml'

module CsBuilder
  module Commands

    class CleanRepos < CoreCommand

      #include Models
      include Io::SafeFileRemoval      

      def initialize(level, config_dir, days, slugs)
        @days = days
        @slugs = slugs
        super('clean_repos', level, config_dir)
      end

      def run(options)
        path_repos = File.join(@config_dir, "repos")
        path_slugs = File.join(@config_dir, "slugs")

        @log.debug "path_repos -> #{path_repos}"
        @log.debug "path_slugs -> #{path_slugs}"

        get_org_dirs(path_repos)
        get_org_dirs(path_slugs) if @slugs
      end

      def get_org_dirs(path)
        Dir["#{path}/*"].each{ |f|
          get_projects(f)
        }
      end

      def get_projects(path)
        Dir["#{path}/*"].each{ |f|
          get_branches(f)
        }
      end

      def get_branches(path)
        Dir["#{path}/*"].each{ |f|
          get_path_date(f)
        }
      end

      def get_path_date(path)
        delete = true
        time_now = Time.now
        time_to_compare = Time.at(time_now - @days * 24 * 60 * 60)
        Dir.glob("#{path}/**/*") { |f| 
          time = File.mtime(f) 
          delete =false if time > time_to_compare
        }

        cleanup(path) if delete
      end
      
      def cleanup(path)
        @log.debug("CLEAN content of #{path}, it's more than #{@days} days OLD")
        safely_remove(path)
      end

    end
  end
end
