module CsBuilder

  module ShellRunner
    def run_shell_cmd(cmd, strip_ansi: true)
      strip_ansi = strip_ansi || true
      IO.popen(cmd) do |io|
        while line = io.gets
          cleaned = line.chomp
          cleaned.gsub!(/\e\[[^m]*m/, '') if strip_ansi
          puts "#{cleaned}" unless cleaned == nil or cleaned.empty?
        end
        io.close
        raise "shell command: [#{cmd}] - threw an error" if $?.to_i != 0
      end
    end
  end
end
