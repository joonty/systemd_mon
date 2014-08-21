module SystemdMon
  class Monitor
    def initialize(dbus_manager)
      self.dbus_manager = dbus_manager
      self.units        = []
      self.callback     = lambda(&method(:unit_change_callback))
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

    def on_unit_change(&callback)
      self.callback = callback
    end

    def start
      units.each do |unit|
        unit.on_change(&callback)
      end
      dbus_manager.runner.run
    end
protected
    attr_accessor :units, :dbus_manager, :callback

    def unit_change_callback(unit, notifier)
      puts "Unit changed: #{unit.name}, #{unit.active_state}, #{unit.sub_state}"
      notifier.
    end
  end
end
