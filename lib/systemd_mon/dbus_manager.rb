require 'dbus'
require 'systemd_mon/error'
require 'systemd_mon/unit'

module SystemdMon
  class DBusManager
    def initialize
      self.dbus            = DBus::SystemBus.instance
      self.systemd_service = dbus.service("org.freedesktop.systemd1")
      self.systemd_object  = systemd_service.object("/org/freedesktop/systemd1")
      systemd_object.introspect
      systemd_object.Subscribe
    end

    def fetch_unit(unit_name)
      path = systemd_object.GetUnit(unit_name).first
      Unit.new(unit_name, path, systemd_service.object(path))
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
