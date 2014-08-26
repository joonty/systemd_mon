module SystemdMon
  class Logger
    def self.verbose=(flag)
      @verbose = flag
    end

    def self.verbose
      @verbose
    end

    def self.debug(message = nil, stream = $stdout)
      if verbose
        if block_given?
          $stdout.puts yield
        else
          $stdout.puts message
        end
      end
    end

    def self.error(message = nil)
      $stderr.puts message
    end

    def self.debug_error(message = nil)
      debug message, $stderr
    end

    def self.puts(message = nil)
      $stdout.puts message
    end
  end
end
