require 'systemd_mon/state_value'

module SystemdMon
  class State
    include Enumerable

    attr_reader :active, :sub, :loaded, :unit_file, :all_states

    def initialize(active, sub, loaded, unit_file)
      @active     = StateValue.new("active", active, %w(active), %w(inactive))
      @sub        = StateValue.new("status", sub)
      @loaded     = StateValue.new("loaded", loaded, %w(loaded))
      @unit_file  = StateValue.new("file", unit_file, %w(enabled), %w(disabled))
      @all_states = [@active, @sub, @loaded, @unit_file]
    end

    def each
      @all_states.each do |state|
        yield state
      end
    end

    def ok?
      all?(&:ok?)
    end

    def fail?
      any?(&:fail?)
    end
  end

end
