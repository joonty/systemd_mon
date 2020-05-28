require 'systemd_mon/error'
require 'systemd_mon/notifiers/base'
require 'systemd_mon/formatters/state_table_formatter'

module SystemdMon::Notifiers
  class Stdout < Base
    def initialize(*)
      super
    end

    def notify_start!(hostname)
      message = "SystemdMon is starting on #{hostname}"

      STDOUT.puts message
    end

    def notify_stop!(hostname)
      message = "SystemdMon is stopping on #{hostname}"

      STDOUT.puts message
    end

    def notify!(notification)
      unit = notification.unit

      subject = "#{notification.type_text}: #{unit.name} on #{notification.hostname}: #{unit.state_change.status_text}"
      message = "Systemd unit #{unit.name} on #{notification.hostname} #{unit.state_change.status_text}: #{unit.state.active} (#{unit.state.sub})\n\n"
      if unit.state_change.length > 1
        message << SystemdMon::Formatters::StateTableFormatter.new(unit).as_text
      end
      message << "\nRegards, SystemdMon"

      STDOUT.puts subject
      STDOUT.puts message
    end
  end
end
