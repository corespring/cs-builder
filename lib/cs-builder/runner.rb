require_relative './log/logger'

module CsBuilder

  module Runner

    @@log = CsBuilder::Log.get_logger('runner')

    def runner_error(path)
      "Lock exists -> #{path} - this means that the same process is already running"
    end

    def run_with_lock(lock_path)
      raise runner_error(lock_path) if has_lock?(lock_path)
      add_lock(lock_path)
      begin
        yield
      rescue => e
        @@log.warn("--------> an error has occured when running the lock - see above to see the cause of the error")
        raise e
      ensure
        remove_lock(lock_path)
      end
    end

    private

    def has_lock?(path)
      has = File.exists?(path)
      @@log.debug "has lock? #{path} #{has}"
      has
    end

    def add_lock(path)
      @@log.info "add_lock: #{path}"
      FileUtils.mkdir_p(File.dirname(path), :verbose => @@log.debug?)
      File.write(path, path)
    end

    def remove_lock(path)
      @@log.info "remove_lock: #{path}"
      FileUtils.rm_rf(path, :verbose => @@log.debug?)
    end
  end
end
