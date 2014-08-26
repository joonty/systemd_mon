require 'thread'
require 'systemd_mon/logger'
require 'systemd_mon/callback_manager'
require 'systemd_mon/notification_centre'
require 'systemd_mon/notification'
require 'systemd_mon/error'

module SystemdMon
  class Monitor
    def initialize(dbus_manager)
      self.hostname     = `hostname`.strip
      self.dbus_manager = dbus_manager
      self.units        = []
      self.change_callback     = lambda(&method(:unit_change_callback))
      self.notification_centre = NotificationCentre.new
    end

    def add_notifier(notifier)
      notification_centre << notifier
      self
    end

    def register_unit(unit_name)
      self.units << dbus_manager.fetch_unit(unit_name)
      self
    end

    def register_units(*unit_names)
      self.units.concat unit_names.flatten.map { |unit_name|
        dbus_manager.fetch_unit(unit_name)
      }
      self
    end

    def on_change(&callback)
      self.change_callback = callback
      self
    end

    def on_each_state_change(&callback)
      self.each_state_change_callback = callback
      self
    end

    def start
      startup_check!

      state_q = Queue.new
      units.each do |unit|
        unit.register_listener! state_q
      end

      Logger.puts "Monitoring changes to #{units.count} units"
      Logger.debug { " - " + units.map(&:name).join("\n - ") + "\n\n" }
      Logger.debug { "Using notifiers: #{notification_centre.classes.join(", ")}"}

      threads = []
      manager = CallbackManager.new(state_q)

      Thread.abort_on_exception = true

      threads << Thread.new do
        manager.start change_callback, each_state_change_callback
      end
      threads << Thread.new do
        dbus_manager.runner.run
      end
      threads.each(&:join)

    end

protected
    attr_accessor :units, :dbus_manager, :change_callback, :each_state_change_callback, :hostname, :notification_centre

    def startup_check!
      unless units.any?
        raise MonitorError, "At least one systemd unit should be registered before monitoring can start"
      end
      unless notification_centre.any?
        raise MonitorError, "At least one notifier should be registered before monitoring can start"
      end
      self
    end

    def unit_change_callback(unit)
      Logger.puts "#{unit.name} #{unit.state_change.status_text}: #{unit.state.active} (#{unit.state.sub})"
      Logger.debug unit.state_change.to_s
      Logger.puts
      notification_centre.notify! Notification.new(hostname, unit)
    end
  end
end
