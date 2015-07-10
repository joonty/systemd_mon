module SystemdMon
  class StateValue
    attr_reader :name, :value, :ok_states, :failure_states, :timestamp

    def initialize(name, value, timestamp, ok_states = [], failure_states = [])
      self.name = name
      self.value = value
      self.ok_states = ok_states
      self.failure_states = failure_states
      self.timestamp = timestamp
    end

    def display_name
      name.capitalize
    end

    def important?
      ok_states.include?(value) || failure_states.include?(value)
    end

    def ok?
      if ok_states.any?
        ok_states.include?(value)
      else
        true
      end
    end

    def fail?
      if failure_states.any?
        failure_states.include?(value)
      else
        false
      end
    end

    def to_s
      value
    end

    def ==(other)
      other.is_a?(SystemdMon::StateValue) && value == other.value
    end

  protected
    attr_writer :name, :value, :ok_states, :failure_states, :timestamp
  end
end
