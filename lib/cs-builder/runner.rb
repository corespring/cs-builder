module CsBuilder

  module Runner

    def runner_log(msg)
      puts msg
    end

    def run_with_lock(lock_path)
      raise "Lock exists -> #{lock_path} - this means that the same process is already running" if has_lock?(lock_path)
      add_lock(lock_path)
      begin
        yield
      rescue => e 
        runner_log("--------> lock error!")
        raise e
      ensure
        remove_lock(lock_path)
      end
    end

    private 

    def has_lock?(path)
      has = File.exists?(path)
      runner_log "has lock? #{path} #{has}"
      has
    end

    def add_lock(path)
      runner_log "add_lock: #{path}"
      FileUtils.mkdir_p(File.dirname(path), :verbose => true)
      File.write(path, path)
    end

    def remove_lock(path)
      runner_log "remove_lock: #{path}"
      FileUtils.rm_rf(path, :verbose => true)
    end
  end
end