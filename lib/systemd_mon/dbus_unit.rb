require 'systemd_mon/state'

module SystemdMon
  class DBusUnit
    attr_reader :name

    IFACE_UNIT  = "org.freedesktop.systemd1.Unit"
    IFACE_PROPS = "org.freedesktop.DBus.Properties"

    def initialize(name, path, dbus_object)
      self.name = name
      self.path = path
      self.dbus_object = dbus_object
      prepare_dbus_objects!
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
      "#{name}"
    end

  protected
    attr_accessor :path, :dbus_object, :change_callback, :each_state_change_callback
    attr_writer   :name

    def build_state
      State.new(
        property("ActiveState"),
        property("SubState"),
        property("LoadState"),
        property("UnitFileState")
      )
    end

    def prepare_dbus_objects!
      dbus_object.introspect
      self.dbus_object.default_iface = IFACE_PROPS
      self
    end
  end
end
