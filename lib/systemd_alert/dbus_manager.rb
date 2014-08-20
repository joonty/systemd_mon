require 'dbus'
module SystemdAlert
  class DBusManager
    def initialize
      @dbus = DBus::SystemBus.instance
      @systemd_service = bus.service("org.freedesktop.systemd1")
      @systemd_object = @systemd_service.object("/org/freedesktop/systemd1")
      @systemd_object.introspect
      @systemd_object.Subscribe
    end
  end
end
