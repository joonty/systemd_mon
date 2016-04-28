require 'systemd_mon/unit_with_state'

module SystemdMon
  class CallbackManager
    def initialize(queue)
      self.queue  = queue
      self.states = Hash.new { |h, u| h[u] = UnitWithState.new(u) }
    end

    def start(change_callback, each_state_change_callback, initial_state_callback)
      first = true
      loop do
        unit, state = queue.deq
        Logger.debug { "#{unit} new state: #{state} in change loop" }
        unit_state = states[unit]
        unit_state << state

        if first && initial_state_callback
          Logger.debug { "#{unit} initial state: #{state} in change loop" }
          with_error_handling { initial_state_callback.call(unit_state) }
        end

        if each_state_change_callback
          with_error_handling { each_state_change_callback.call(unit_state) }
        end

        if change_callback && unit_state.state_change.important?
          with_error_handling { change_callback.call(unit_state) }
        end

        unit_state.reset! if unit_state.state_change.important?
        first = false
      end
    end

    def with_error_handling
      yield
    rescue => e
      Logger.error "Uncaught exception (#{e.class}) in callback: #{e.message}"
      Logger.error "\n\t#{e.backtrace.join("\n\t")}\n"
    end

  protected
    attr_accessor :queue, :states
  end
end
