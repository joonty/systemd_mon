module SystemdMon
  class StateChange
    include Enumerable

    attr_reader :states

    def initialize(original_state = nil)
      self.states = []
      states << original_state if original_state
    end

    def last
      states.last
    end

    def length
      states.length
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

    def restart?
      first.ok? && last.ok? && changes.any? { |s| s.active == "deactivating" }
    end

    def auto_restart?
      first.ok? && last.ok? && changes.any? { |s| s.sub == "auto-restart" }
    end

    def reload?
      first.ok? && last.ok? && changes.any? { |s| s.active == "reloading" }
    end

    def still_fail?
      length > 1 && first.fail? && last.fail?
    end

    def status_text
      if recovery?
        "recovered"
      elsif auto_restart?
        "automatically restarted"
      elsif restart?
        "restarted"
      elsif reload?
        "reloaded"
      elsif still_fail?
        "still failed"
      elsif fail?
        "failed"
      else
        "started"
      end
    end

    def important?
      if length == 1
        first.fail?
      else
        diff.map(&:last).any?(&:important?)
      end
    end

    def diff
      @diff ||= zipped.reject { |states|
        states = states.kind_of?(Array) ? states : [states]
        match = states.first.value
        states.all? { |s| s.value == match }
      }
    end

    def zipped
      if length == 1
        first.all_states
      else
        first.all_states.zip(*changes.map(&:all_states))
      end
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
