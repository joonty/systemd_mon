require 'systemd_mon/state'

module SystemdMon
  class DBusUnit
    attr_reader :name, :maybe_service_type

    IFACE_UNIT    = "org.freedesktop.systemd1.Unit"
    IFACE_SERVICE = "org.freedesktop.systemd1.Service"
    IFACE_PROPS   = "org.freedesktop.DBus.Properties"

    def initialize(name, path, dbus_object)
      self.name = name
      self.path = path
      self.dbus_object = dbus_object
      prepare_dbus_objects!
      self.maybe_service_type = service_type
    end

    def register_listener!(queue)
      queue.enq [self, build_state] # initial state
      dbus_object.on_signal("PropertiesChanged") do |iface|
        if iface == IFACE_UNIT
          queue.enq [self, build_state]
        end
      end
    end

    def on_change(&callback)
      self.change_callback = callback
    end

    def on_each_state_change(&callback)
      self.each_state_change_callback = callback
    end

    def property(name)
      dbus_object.Get(IFACE_UNIT, name).first
    end

    def to_s
      "#{name}" << (maybe_service_type ? " (#{maybe_service_type})" : '')
    end

  protected
    attr_accessor :path, :dbus_object, :change_callback, :each_state_change_callback
    attr_writer   :name, :maybe_service_type

    def build_state
      State.new(
        property("ActiveState"),
        property("SubState"),
        property("LoadState"),
        property("UnitFileState"),
        maybe_service_type
      )
    end

    def prepare_dbus_objects!
      dbus_object.introspect
      self.dbus_object.default_iface = IFACE_PROPS
      self
    end

    def service_type
      if dbus_object[IFACE_SERVICE]
        dbus_object[IFACE_SERVICE]['Type']
      end
    end
  end
end
