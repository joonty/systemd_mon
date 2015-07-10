require 'systemd_mon/state_value'

module SystemdMon
  class State
    include Enumerable

    attr_reader :active, :sub, :loaded, :unit_file, :all_states

    def initialize(active, sub, loaded, unit_file, type=nil)
      timestamp   = Time.now
      @active     = StateValue.new("active", active, timestamp, *active_states(type))
      @sub        = StateValue.new("status", sub, timestamp)
      @loaded     = StateValue.new("loaded", loaded, timestamp, %w(loaded))
      @unit_file  = StateValue.new("file", unit_file, timestamp, *file_states(type))
      @all_states = [@active, @sub, @loaded, @unit_file]
    end

    def active_states(type)
      case type
      when 'oneshot'
        [%w(inactive), %w(failed)]
      else
        [%w(active), %w(inactive failed)]
      end
    end

    def file_states(type)
      case type
      when 'oneshot'
        [[], []]
      else
        [%w(enabled), %w(disabled)]
      end
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

    def ==(other)
      @all_states == other.all_states
    end
  end

end
