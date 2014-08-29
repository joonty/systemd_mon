module SystemdMon
  class Notification
    attr_reader :unit, :type, :hostname

    def initialize(hostname, unit)
      self.hostname = hostname
      self.unit     = unit
      self.type     = determine_type
    end

    def self.types
      [:alert, :warning, :info, :ok]
    end

    def type_text
      type.to_s.capitalize
    end

  protected
    attr_writer :unit, :type, :hostname

    def determine_type
      if unit.state_change.ok?
        if unit.state_change.first.fail?
          :ok
        else
          :info
        end
      else
        :alert
      end
    end
  end
end
