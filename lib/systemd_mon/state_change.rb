module SystemdMon
  class StateChange
    include Enumerable

    attr_reader :states

    def initialize(original_state)
      self.states = [original_state]
    end

    def last
      states.last
    end

    def <<(state)
      self.states << state
      @diff = nil
    end

    def each
      states.each do |state|
        yield state
      end
    end

    def changes
      states[1..-1]
    end

    def recovery?
      first.fail? && last.ok?
    end

    def ok?
      last.ok?
    end

    def fail?
      last.fail?
    end

    def still_fail?
      first.fail? && last.fail?
    end

    def status_text
      if recovery?
        "recovered"
      elsif still_fail?
        "still failing"
      elsif fail?
        "failed"
      else
        "ok"
      end
    end

    def important?
      diff.map(&:last).any?(&:important?)
    end

    def diff
      @diff ||= zipped.reject { |states|
        match = states.first.value
        states.all? { |s| s.value == match }
      }
    end

    def zipped
      first.all_states.zip(*changes.map(&:all_states))
    end

    def to_s
      diff.inject("") { |s, (*states)|
        first = states.shift
        s << "#{first.name} state changed from #{first.value} to "
        s << states.map(&:value).join(" then ")
        s << "\n"
        s
      }
    end

  protected
    attr_accessor :original, :changed
    attr_writer :states
  end

end
