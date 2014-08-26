require 'systemd_mon/state_change'

module SystemdMon
  class UnitWithState
    attr_reader :unit, :state_change

    def initialize(unit)
      self.unit         = unit
      self.state_change = StateChange.new
    end

    def name
      unit.name
    end

    def <<(state)
      self.state_change << state
    end

    def current_state
      state_change.last
    end

    def reset!
      self.state_change = StateChange.new(current_state)
    end

    alias :state :current_state

  protected
    attr_writer :state_change, :unit
  end
end
