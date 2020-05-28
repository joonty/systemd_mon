require 'systemd_mon/error'
require 'systemd_mon/notifiers/base'

begin
  require 'dingbot'
rescue LoadError
  raise SystemdMon::NotifierDependencyError, "The 'dingbot' gem is required by the dingtalk notifier"
end

module SystemdMon::Notifiers
  class Ding < Base
    def initialize(*)
      super
      DingBot.configure do |config|
        config.endpoint = options.fetch('endpoint')
        config.access_token = options.fetch('access_token')
      end
    end

    def notify_start!(hostname)
      DingBot.send_text("SystemdMon is starting on #{hostname}")
    end

    def notify_stop!(hostname)
      DingBot.send_text("SystemdMon is stopping on #{hostname}")
    end

    def notify!(notification)
      unit = notification.unit
      message = "#{notification.type_text}: systemd unit #{unit.name} on #{notification.hostname} #{unit.state_change.status_text}: #{unit.state.active} (#{unit.state.sub})"
      DingBot.send_text(message)
      log "sent ding notification"
    end

  protected
    attr_accessor :options
  end
end
