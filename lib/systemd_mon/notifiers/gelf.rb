require 'systemd_mon/error'
require 'systemd_mon/notifiers/base'

begin
  require 'gelf'
rescue LoadError
  raise SystemdMon::NotifierDependencyError, "The 'gelf' gem is required by the gelf notifier"
end


module SystemdMon::Notifiers
  class Gelf < Base
    def initialize(*)
      super
      self.notifier = GELF::Notifier.new("localhost", 12201, "LAN")
    end

    def notify_start!(hostname)
      message = "SystemdMon is starting on #{hostname}"

      notifier.debug(message)
    end

    def notify_stop!(hostname)
      message = "SystemdMon is stopping on #{hostname}"

      notifier.debug(message)
    end

    def notify!(notification)
      unit = notification.unit

      unit.state_change.each do |change|
        msg = {timestamp: change.active.timestamp, short_message: "state change", _unit: unit.name, host: notification.hostname, _active: change.active.value, _sub: change.sub.value, _loaded: change.loaded.value, _enabled: change.unit_file.value }
        notifier.info(msg)
      end
    end

    protected
      attr_accessor :notifier, :options
  end
end
