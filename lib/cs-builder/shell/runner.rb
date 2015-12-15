require_relative '../log/logger'
require 'open3'

module CsBuilder

=begin
  This runner uses popen3 so you have access to the stderr
  Which is nicer.. but it's hanging atm.
  Could it be related to this: 
  http://stackoverflow.com/questions/8952043/how-to-fix-hanging-popen3-in-ruby
  ?
=end
  module NewShellRunner
    
    @@log = CsBuilder::Log.get_logger('shell')
    
    @@shell_log = CsBuilder::Log.get_logger('$')

    def shell_run(cmd, strip_ansi: true)
      @@log.debug("dir: #{Dir.pwd}, cmd: #{cmd}, strip_ansi: #{strip_ansi}")
      strip_ansi = strip_ansi || true
      out = StringIO.new 

      err = StringIO.new

      Open3.popen3(cmd) {|stdin, stdout, stderr, wait_thr|

        stdin.close_write
        exit_status = wait_thr.value # Process::Status object returned.
        while line = stdout.gets
          cleaned = line.chomp
          cleaned.gsub!(/\e\[[^m]*m/, '') if strip_ansi
          out << cleaned
          @@shell_log.info("#{cleaned}") unless cleaned == nil or cleaned.empty?
        end 

        # while e = stderr.gets
        #   @@shell_log.error("#{e.chomp}") 
        #   err << e
        # end
        
        unless exit_status.success?
          IO.copy_stream(stderr, err, 3)
          raise "Shell command: [#{cmd}]\nThrew an error:\n#{err.string}"
        end

        #IO.copy_stream(stdout, out, 3)
        out.string
      }

    end
  end
end

require_relative '../log/logger'

module CsBuilder

  module ShellRunner
    
    @@log = CsBuilder::Log.get_logger('shell')
    
    @@shell_log = CsBuilder::Log.get_logger('$')

    def shell_run(cmd, strip_ansi: true)
      @@log.debug("dir: #{Dir.pwd}, cmd: #{cmd}, strip_ansi: #{strip_ansi}")
      strip_ansi = strip_ansi || true
      out = StringIO.new 
      IO.popen("#{cmd} 2>&1") do |io|
        while line = io.gets
          cleaned = line.chomp
          cleaned.gsub!(/\e\[[^m]*m/, '') if strip_ansi
          out << cleaned
          @@shell_log.info("#{cleaned}") unless cleaned == nil or cleaned.empty?
        end
        io.close
        raise "shell command: [#{cmd}] - threw an error" if $?.to_i != 0
        out.string 
      end
    end
  end
end