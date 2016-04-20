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
      host = options["host"] || "127.0.0.1"
      port = options["port"] || 12201
      max_size = options["network"] || "WAN"
      self.notifier = GELF::Notifier.new(host, port, max_size)
      if options["level"] && !options["level"].empty?
        if GELF::Levels.constants.include? options["level"].upcase.to_sym
          @level = options["level"].downcase.to_sym
        else
          raise SystemdMon::NotifierDependencyError, "The configured loglevel #{options["level"]} is not a valid GELF loglevel"
        end
      else
        @level = :info
      end
    end 

    def notify_start!(hostname)
      message = "SystemdMon is starting on #{hostname}"

      send_notification(message)
    end

    def notify_stop!(hostname)
      message = "SystemdMon is stopping on #{hostname}"

      send_notification(message)
    end

    def notify!(notification)
      unit = notification.unit

      unit.state_change.each do |change|
        msg = {timestamp: change.active.timestamp, short_message: "state change", _unit: unit.name, host: notification.hostname, _active: change.active.value, _sub: change.sub.value, _loaded: change.loaded.value, _enabled: change.unit_file.value }
        send_notification(msg)
      end
    end

    protected
      attr_accessor :notifier, :options, :level

      def send_notification(msg)
        notifier.__send__(level, msg)
      end
  end
end
