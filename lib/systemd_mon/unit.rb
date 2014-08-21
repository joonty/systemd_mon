module SystemdMon
  class Unit

    class Properties
      attr_reader :active_state, :sub_state, :load_state, :unit_file_state

      def initialize(active_state, sub_state, load_state, unit_file_state)
        @active_state    = active_state
        @sub_state       = sub_state
        @load_state      = load_state
        @unit_file_state = unit_file_state
      end
    end

    attr_reader :name
    IFACE_UNIT  = "org.freedesktop.systemd1.Unit"
    IFACE_PROPS = "org.freedesktop.DBus.Properties"

    def initialize(name, path, dbus_object)
      self.name = name
      self.path = path
      self.dbus_object = dbus_object
      dbus_object.introspect
      self.dbus_object.default_iface = IFACE_PROPS
    end

    def on_change
      dbus_object.on_signal("PropertiesChanged") do |iface|

        if iface == IFACE_UNIT
          self.properties = Properties.new(
            property("ActiveState"),
            property("SubState"),
            property("LoadState"),
            property("UnitFileState")
          )
          yield self
          self.prev_properties = self.properties.dup
        end
      end
    end

    def property(name)
      dbus_object.Get(IFACE_UNIT, name).first
    end

    def active_state
      property("ActiveState")
    end

    def sub_state
      property("SubState")
    end

    def load_state
      property("LoadState")
    end

    def unit_file_state
      property("UnitFileState")
    end

  protected
    attr_accessor :path, :dbus_object, :properties, :previous_properties
    attr_writer   :name
  end
end
