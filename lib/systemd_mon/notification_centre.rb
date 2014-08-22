require 'systemd_mon/error'
require 'systemd_mon/logger'

module SystemdMon
  class NotificationCentre
    include Enumerable

    def initialize
      self.notifiers = []
    end

    def classes
      notifiers.map(&:class)
    end

    def each
      notifiers.each do |notifier|
        yield notifier
      end
    end

    def add_notifier(notifier)
      unless notifier.respond_to?(:notify!)
        raise NotifierError, "Notifier #{notifier.class} must respond to 'notify!'"
      end
      self.notifiers << notifier
    end

    def notify!(notification)
      self.notifiers.each do |notifier|
        #Thread.start do
          begin
            Logger.puts "Notifying state change of #{notification.unit.name} via #{notifier.class}"
            notifier.notify! notification
          rescue => e
            err = "Failed to send notification via #{notifier.class}:\n"
            err << "  #{e.class}: #{e.message}\n"
            err << "  Backtrace: #{e.backtrace.join('\n\t')}\n\n"
            Logger.error err
          end
        #end
      end
    end

    alias :<< :add_notifier

  protected
    attr_accessor :notifiers
  end
end
