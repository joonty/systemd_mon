require 'systemd_mon/unit_with_state'

module SystemdMon
  class CallbackManager
    def initialize(queue)
      self.queue  = queue
      self.states = Hash.new { |h, u| h[u] = UnitWithState.new(u) }
    end

    def start(change_callback, each_state_change_callback)
      loop do
        unit, state = queue.deq
        unit_state = fetch_unit_with_state(unit)

        puts "*** #{unit}, #{state.active} #{state.sub}"
        unit_state.state_change.each do |s|
          puts " - #{s.active} #{s.sub}"
        end


        unit_state << state

        if each_state_change_callback
          each_state_change_callback.call(unit_state)
        end
        if change_callback && unit_state.state_change.important?
          change_callback.call(unit_state)
        end
        unit_state.reset! if unit_state.state_change.important?
      end
    end

    def fetch_unit_with_state(unit)
      states[unit]
    end

  protected
    attr_accessor :queue, :states
  end
end
