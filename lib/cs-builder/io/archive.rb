require_relative '../log/logger'
require_relative './utils'
require_relative '../shell/runner'
require 'tmpdir'

module CsBuilder
  module IO
    module Archive
      extend CsBuilder::ShellRunner

      @@log = CsBuilder::Log.get_logger('archive')

      #
      # create an archive using the assets listed.
      # it creates a temporary directory and copies the assets over.
      # Any way i can just use the tar command to do tha
      #
      def self.create(src_dir, out_path, assets)

        binary_folder = Dir.mktmpdir("archive_")
        @@log.debug("[create] src_dir: #{src_dir} -> #{out_path}, binary_folder: #{binary_folder}")

        assets.each{ |asset|
          from = File.join(src_dir, asset)
          to = File.join(binary_folder, asset)
          FileUtils.mkdir_p( File.dirname(to), :verbose => @@log.debug?)
          FileUtils.cp_r(from, to, :verbose => @@log.debug?)
        }

        parent = File.dirname(out_path)
        FileUtils.mkdir_p(parent)
        raise "Parent directory doesn't exist: #{parent}" unless File.exists?(parent) and File.directory?(parent)
        cmd = "tar czvf #{out_path} -C #{binary_folder} ."
        run_shell_cmd(cmd)
        FileUtils.rm_rf(binary_folder, :verbose => @@log.debug?)
        raise "Failed to create Archive: #{out_path}" unless File.exists?(out_path)
        out_path
      end

      # merge archives
      # @param opts {:force => true|false, :custom_path => "."}
      #
      def self.merge(out_path, opts, *archives)
        final_path =  File.extname(out_path) == ".tgz" ? out_path : "#{out_path}.tgz"
        puts "? final_path: #{final_path}, out_path: #{out_path}"
        tmp_dir = final_path.gsub(".tgz", "")

        force = opts.has_key?(:force) and opts[:force] == true

        archives.each{|a|
          raise "archive doesn't exist: #{a}" unless File.exists?(a)
          raise "archive must be a .tgz: #{a}" unless File.extname(a) == ".tgz"
        }

        @@log.debug("final_path: #{final_path}, tmp_dir: #{tmp_dir}, force: #{force}")

        FileUtils.rm_rf(tmp_dir, :verbose => @@log.debug?) if force 
        FileUtils.rm_rf(final_path, :verbose => @@log.debug?) if force

        if(File.exists?(final_path) and !force)
          @@log.warn("That archive already exists - skipping")
        else
          FileUtils.mkdir_p(tmp_dir, :verbose => @@log.debug?)

          archives.each{|a|
            @@log.info("extract #{a} -> #{tmp_dir}")
            run_shell_cmd("tar xzvf #{a} -C #{tmp_dir}")
          }

          @@log.debug "compress folder to a new archive: #{final_path}"
          custom_path = opts.has_key?(:custom_path) ? opts[:custom_path] : "." 
          cmd = "tar czvf #{final_path} -C #{tmp_dir}"
          cmd << " #{custom_path}" unless custom_path.empty?
          @@log.debug("cmd: #{cmd}")
          run_shell_cmd(cmd)
          FileUtils.rm_rf tmp_dir, :verbose => true
          raise "failed to create tgz" unless File.exists?(final_path)
        end
        final_path
      end
    end
  end
end