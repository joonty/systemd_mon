require 'systemd_mon/error'
require 'systemd_mon/notifiers/base'

begin
  require 'hipchat'
rescue LoadError
  raise SystemdMon::NotifierDependencyError, "The 'hipchat' gem is required by the hipchat notifier"
end

module SystemdMon::Notifiers
  class Hipchat < Base
    def initialize(*)
      super
      self.client = ::HipChat::Client.new(
          options['token'],
          :api_version => 'v2')
    end

    def notify_start!(hostname)
      chat "SystemdMon is starting on #{hostname}",
           'green'
    end

    def notify_stop!(hostname)
      chat "SystemdMon is stopping on #{hostname}",
           'yellow'
    end

    def notify!(notification)
      unit = notification.unit
      message = "#{notification.type_text}: systemd unit #{unit.name} on #{notification.hostname} #{unit.state_change.status_text}: #{unit.state.active} (#{unit.state.sub})"

      chat message,
           color(notification.type)

      log "sent hipchat notification"
    end

  protected
    attr_accessor :client, :options

    def chat(message, shade)
      client[options['room']].send(
        options['username'],
        message,
        :color => shade)
    end

    def color(type)
      case type
      when :alert
        'red'
      when :warning
        'yellow'
      when :info
        'purple'
      else
        'green'
      end
    end
  end
end
