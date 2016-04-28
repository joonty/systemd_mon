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

    def notify_start!(hostname)
      each_notifier do |notifier|
        if notifier.respond_to?(:notify_start!)
          Logger.puts "Notifying SystemdMon start via #{notifier.class}"
          notifier.notify_start! hostname
        else
          Logger.debug { "#{notifier.class} doesn't respond to 'notify_start!', not sending notification" }
        end
      end
    end

    def notify_stop!(hostname)
      each_notifier do |notifier|
        if notifier.respond_to?(:notify_stop!)
          Logger.puts "Notifying SystemdMon stop via #{notifier.class}"
          notifier.notify_stop! hostname
        else
          Logger.debug { "#{notifier.class} doesn't respond to 'notify_start!', not sending notification" }
        end
      end
    end

    def initial_state!(notification)
      Logger.debug "initial state"
      each_notifier do |notifier|
        if notifier.respond_to?(:initial_state!)
          Logger.puts "Notifying state change of #{notification.unit.name} via #{notifier.class}"
          notifier.initial_state!(notification)
        else
          Logger.debug { "#{notifier.class} doesn't respond to 'initial_state!', not setting initial state" }
        end
      end
    end

    def notify!(notification)
      each_notifier do |notifier|
        Logger.puts "Notifying state change of #{notification.unit.name} via #{notifier.class}"
        notifier.notify! notification
      end
    end

    alias :<< :add_notifier

  protected
    attr_accessor :notifiers

    def each_notifier
      notifiers.map { |notifier|
        Thread.new do
          begin
            yield notifier
          rescue => e
            Logger.error "Failed to send notification via #{notifier.class}:\n"
            Logger.error "  #{e.class}: #{e.message}\n"
            Logger.error { "\n\t#{e.backtrace.join('\n\t')}\n" }
          end
        end
      }.each(&:join)
    end
  end
end
