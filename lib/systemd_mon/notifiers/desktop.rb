require 'systemd_mon/error'
require 'systemd_mon/notifiers/base'
require 'systemd_mon/formatters/state_table_formatter'


module SystemdMon::Notifiers
  class Desktop < Base
    bus = DBus::SessionBus.instance
    not_service = bus.service("org.freedesktop.Notifications")
    not_object = not_service.object("/org/freedesktop/Notifications")
    not_object.introspect
    DesktopNotifier = not_object["org.freedesktop.Notifications"]

    def initialize(*)
      super
      if options['start_stop_message']
        @startstopmessage = true
      else
        @startstopmessage = false
      end
      if options['timeout']
        @timeout = timeout
      else
        @timeout = 2000
      end
    end


    def notify_start!(hostname)
      if @startstopmessage
        DesktopNotifier.Notify("Systemd_mon", 0, "info", "Started", "", [], {}, @timeout)
      end
    end

    def notify_stop!(hostname)
      if @startstopmessage
        DesktopNotifier.Notify("Systemd_mon", 0, "info", "Stopped", "", [], {}, @timeout)
      end
    end

    def notify!(notification)
      unit = notification.unit
      DesktopNotifier.Notify("Systemd_mon", 0, "#{notification.type_text}", "#{unit.name} changed to #{unit.state_change.status_text}", "", [], {}, @timeout)
    end
  end
end
