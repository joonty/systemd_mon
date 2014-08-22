require 'systemd_mon/state'
require 'systemd_mon/state_change'

module SystemdMon
  class Unit
    attr_reader :name, :state, :state_change

    IFACE_UNIT  = "org.freedesktop.systemd1.Unit"
    IFACE_PROPS = "org.freedesktop.DBus.Properties"

    def initialize(name, path, dbus_object)
      self.name = name
      self.path = path
      self.dbus_object = dbus_object
      prepare_dbus_objects!

      self.state = build_state
      self.state_change = StateChange.new(state)

      register_listener!
    end

    def register_listener!
      dbus_object.on_signal("PropertiesChanged") do |iface|
        if iface == IFACE_UNIT
          self.state = build_state
          self.state_change << state

          if each_state_change_callback
            each_state_change_callback.call self
          end
          if change_callback && state_change.important?
            change_callback.call self
            reset_state_change!
          end
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

  protected
    attr_accessor :path, :dbus_object, :change_callback, :each_state_change_callback
    attr_writer   :name, :state, :prev_state, :state_change

    def build_state
      State.new(
        property("ActiveState"),
        property("SubState"),
        property("LoadState"),
        property("UnitFileState")
      )
    end

    def reset_state_change!
      self.state_change = StateChange.new(state)
    end

    def prepare_dbus_objects!
      dbus_object.introspect
      self.dbus_object.default_iface = IFACE_PROPS
      self
    end
  end
end
