module SystemdMon

  # Save original exception for use in verbose mode
  class Error < StandardError
    attr_reader :original

    def initialize(msg, original=$!)
      super(msg)
      @original = original
    end
  end

  class UnknownUnitError < Error; end
  class NotificationError < Error; end
end
