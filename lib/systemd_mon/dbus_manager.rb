require 'dbus'
require 'systemd_mon/error'
require 'systemd_mon/dbus_unit'

module SystemdMon
  class DBusManager
    def initialize
      self.dbus            = DBus::SystemBus.instance
      self.systemd_service = dbus.service("org.freedesktop.systemd1")
      self.systemd_object  = systemd_service.object("/org/freedesktop/systemd1")
      systemd_object.introspect
      if systemd_object.respond_to?("Subscribe")
        systemd_object.Subscribe
      else
        raise SystemdMon::SystemdError, "Systemd is not installed, or is an incompatible version. It must provide the Subscribe dbus method: version 204 is the minimum recommended version."
      end
    end

    def fetch_unit(unit_name)
      path = systemd_object.GetUnit(unit_name).first
      DBusUnit.new(unit_name, path, systemd_service.object(path))
    rescue DBus::Error
      raise SystemdMon::UnknownUnitError, "Unknown or unloaded systemd unit '#{unit_name}'"
    end

    def runner
      main = DBus::Main.new
      main << dbus
      main
    end

  protected
    attr_accessor :systemd_service, :systemd_object, :dbus
  end
end
