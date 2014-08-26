require 'slack-notifier'
require 'systemd_mon/notifiers/base'

module SystemdMon::Notifiers
  class Slack < Base
    def initialize(*)
      super
      self.notifier = ::Slack::Notifier.new(
        options.fetch('team'),
        options.fetch('token'),
        channel: options['channel'],
        username: options['username'],
        icon_emoji: options['icon_emoji'],
        icon_url: options['icon_url'])
    end

    def notify_start!(hostname)
      message = "Startup notification for SystemdMon"

      attach = {
        fallback: message,
        text: "SystemdMon is starting on #{hostname}",
        color: "good"
      }

      notifier.ping message, attachments: [attach]
    end

    def notify_stop!(hostname)
      message = "Shutdown alert for SystemdMon"

      attach = {
        fallback: message,
        text: "SystemdMon is stopping on #{hostname}",
        color: "danger"
      }

      notifier.ping message, attachments: [attach]
    end

    def notify!(notification)
      unit = notification.unit
      message = "Systemd unit #{unit.name} on #{notification.hostname} #{unit.state_change.status_text}"

      attach = {
        fallback: "#{message}: #{unit.state.active} (#{unit.state.sub})",
        color: color(notification.type),
        fields: fields(notification)
      }

      debug("sending slack message with attachment: ")
      debug(attach.inspect)

      notifier.ping message, attachments: [attach]
      log "sent slack notification"
    end

  protected
    attr_accessor :notifier

    def fields(notification)
      f = [
        {
          title: "Hostname",
          value: notification.hostname,
          short: true
        },
        {
          title: "Unit",
          value: notification.unit.name,
          short: true
        }
      ]

      changes = notification.unit.state_change.diff.map(&:last)
      f.concat(changes.map { |v|
        { title: v.display_name, value: v.value, short: true }
      })
    end

    def color(type)
      case type
      when :alert
        'danger'
      when :info
        '#0099CC'
      else
        'good'
      end
    end
  end
end
