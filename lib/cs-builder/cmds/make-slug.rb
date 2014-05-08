require_relative './core-command'
require_relative '../git-parser'

module CsBuilder
  module Commands


    class MakeSlug < CoreCommand
      def initialize(level, config_dir)
        super('make_slug', level, config_dir)
      end

      def run(options)
        @log.info "running MakeSlug"
        template = options[:template]
        init_template(template)
        build_slug(options)
      end

      def init_template(name)
        if !File.exists?(template_archive(name))
          @log.info "need to install the template for #{name}.. please wait..."
          install_template(name)
        else
          @log.debug("Formula already exists for #{name}")
        end
      end

      def formula(name)
        File.join(@config_dir, "templates", "formulas", name)
      end

      def template_archive(name)
        File.join(@config_dir, "templates", "built", "#{name}.tgz")
      end

      def install_template(name)
        @log.debug "need to install template, looking for a formla for #{name}"
        script = formula("#{name}.formula")
        raise "No formula found for #{script}" unless File.exists? script
        mkdir_if_needed(File.join(@config_dir, "templates", "built"))
        in_dir(File.dirname(script)){
          File.chmod(0755, "#{name}.formula")
          @log.debug "running formula.. please wait"
          run_cmd "./#{name}.formula ../built"
        }
      end

      def build_slug(options)
        template = options[:template]
        binary = options[:binary]
        archive = template_archive(template)
        raise "Archive doesn't exist: #{archive}" unless File.exists? archive
        output = options[:output]
        basename = File.basename(output)
        output_dir = output.gsub(".tgz", "")
        app_path = File.join(output_dir, "app")

        @log.debug "binary path to add to tar: #{binary}"

        if File.exists?(output)
          @log.info "File #{output} already exists"
        else
          FileUtils.mkdir_p app_path, :verbose => true
          @log.debug "extract #{archive} -> #{app_path}"
          `tar xvf #{archive} -C #{app_path}`
          @log.debug "extract #{binary} -> #{app_path}"
          `tar xvf #{binary} -C #{app_path}`
          @log.debug "compress folder to a new archive: #{output}.tgz"

          `tar czvf #{output} -C #{output_dir} ./app`
          #in_dir(output_dir){
          #  `tar czvf #{basename} ./app`
          #}
          #Note: the './app' is significant here
          FileUtils.rm_rf output_dir, :verbose => true
        end

      end
    end

    class MakeGitSlug < CoreCommand

      def initialize(level, config_dir)
        super('make_slug', level, config_dir)
      end

      def run(options)
        @log.info "running MakeSlug"
        template = options[:template]
        init_template(template)
        build_slug(options)
      end

      protected

      def init_template(name)
        if !File.exists?(installed_path(extra: "/#{name}.tgz"))
          @log.info "need to install the template for #{name}.. please wait..."
          install_template(name)
        else
          @log.debug("Formula already exists for #{name}")
        end
      end

      def install_template(name)

        @log.debug "need to install template, looking for a formla for #{name}"
        script = formula_path(extra: "/#{name}.formula")
        raise "No formula found for #{script}" unless File.exists? script
        in_dir(formula_path){
          File.chmod(0755, "#{name}.formula")
          @log.debug "running formula.. please wait"
          run_cmd "./#{name}.formula ../built"
        }
      end

      def build_slug(options)

        git = options[:git]
        org = GitParser.org(git)
        repo = GitParser.repo(git)
        branch = options[:branch]
        template_archive = installed_path(extra: "/#{options[:template]}.tgz")
        raise "Archive doesn't exist: #{template_archive}" unless File.exists? template_archive

        sha = get_sha(org, repo, branch)

        final_slug_path = slug_path(org, repo, branch, sha)
        app_path = final_slug_path + "/app"

        binaries_path = binary_archive_path(binaries_path(org, repo, branch), sha, suffix: ".tgz")

        @log.debug "binary path to add to tar: #{binaries_path}"


        if File.exists?(final_slug_path)
          @log.info "File #{final_slug_path} already exists"
        else
          FileUtils.mkdir_p app_path, :verbose => true
          @log.debug "extract #{template_archive} -> #{app_path}"
          `tar xvf #{template_archive} -C #{app_path}`
          @log.debug "extract #{binaries_path} -> #{app_path}"
          `tar xvf #{binaries_path} -C #{app_path}`
          @log.debug "compress folder to a new archive: #{final_slug_path}.tgz"

          in_dir(final_slug_path){
            `tar czvf slug-#{sha}.tgz ./app`
          }
          #Note: the './app' is significant here
          FileUtils.rm_rf app_path, :verbose => true
        end

      end

      def slug_path(org, repo, branch, sha, extra: "")
        "#{@config_dir}/slugs/#{org}/#{repo}/#{branch}/#{sha}" << extra
      end

      def installed_path(extra: ""  )
        "#{@config_dir}/templates/built" << extra
      end

      def formula_path(extra: "")
        "#{@config_dir}/templates/formulas" << extra
      end
    end
  end
end
