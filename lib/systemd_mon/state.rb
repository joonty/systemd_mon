require 'systemd_mon/state_value'

module SystemdMon
  class State
    include Enumerable

    attr_reader :active, :sub, :loaded, :unit_file, :all_states

    def initialize(active, sub, loaded, unit_file)
      timestamp   = Time.now
      @active     = StateValue.new("active", active, timestamp, %w(active), %w(inactive failed))
      @sub        = StateValue.new("status", sub, timestamp)
      @loaded     = StateValue.new("loaded", loaded, timestamp, %w(loaded))
      @unit_file  = StateValue.new("file", unit_file, timestamp, %w(enabled), %w(disabled))
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

    def to_s
      @all_states.join(', ')
    end
  end

end
