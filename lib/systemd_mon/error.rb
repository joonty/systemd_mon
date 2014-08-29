module SystemdMon

  # Save original exception for use in verbose mode
  class Error < StandardError
    attr_reader :original

    def initialize(msg, original=$!)
      super(msg)
      @original = original
    end
  end

  class MonitorError < Error; end
  class UnknownUnitError < Error; end
  class NotificationError < Error; end
  class NotifierDependencyError < Error; end
  class NotifierError < Error; end
end
