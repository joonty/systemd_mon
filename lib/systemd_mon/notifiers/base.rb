require 'systemd_mon/logger'

module SystemdMon::Notifiers
  class Base
    def initialize(options)
      self.options = options
      self.me      = self.class.name
    end

    # Subclasses must respond to a unit change
    def notify!(notification)
      raise "Notifier #{self.class} does not respond to notify!"
    end

    # Subclasses can choose to do something when SystemdMon starts
    # E.g. with
    #
    # def notify_start!(hostname)
    # end

    # Subclasses can choose to do something when SystemdMon stops
    # E.g. with
    #
    # def notify_stop!(hostname)
    # end

    def log(message)
      SystemdMon::Logger.puts "#{me}: #{message}"
    end

    def debug(message = nil, &blk)
      message = "#{me}: #{message}" if message
      SystemdMon::Logger.debug message, &blk
    end

  protected
    attr_accessor :options, :me
  end
end
