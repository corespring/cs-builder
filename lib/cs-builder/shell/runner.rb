require_relative '../log/logger'

module CsBuilder

  module ShellRunner
    
    @@log = CsBuilder::Log.get_logger('shell')
    
    @@shell_log = CsBuilder::Log.get_logger('$')

    def shell_run(cmd, strip_ansi: true)
      @@log.debug("dir: #{Dir.pwd}, cmd: #{cmd}, strip_ansi: #{strip_ansi}")
      strip_ansi = strip_ansi || true
      out = []
      IO.popen(cmd) do |io|
        while line = io.gets
          cleaned = line.chomp
          cleaned.gsub!(/\e\[[^m]*m/, '') if strip_ansi
          out << cleaned
          @@shell_log.info("#{cleaned}") unless cleaned == nil or cleaned.empty?
        end
        io.close
        raise "shell command: [#{cmd}] - threw an error" if $?.to_i != 0
        out.join("\n")
      end
    end
  end
end
