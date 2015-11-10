require 'systemd_mon/error'
require 'systemd_mon/notifiers/base'

begin
  require 'flowdock'
rescue LoadError
  raise SystemdMon::NotifierDependencyError, "The 'flowdock' gem is required by the flowdock notifier"
end

module SystemdMon::Notifiers
  class Flowdock < Base
    def initialize(*)
      super
      self.client = ::Flowdock::Client.new(flow_token: options['token'])
    end

    def notify_start!(hostname)
      thread_id = "systemd_mon-#{hostname}"
      title = "SystemdMon is starting on #{hostname}"
      message = ""
      chat title, message, thread_id, 'green', "starting"
    end

    def notify_stop!(hostname)
      thread_id = "systemd_mon-#{hostname}"
      title = "SystemdMon is stopping on #{hostname}"
      message = ""
      chat title, message, thread_id, 'yellow', "stopping"
    end

    def notify!(notification)
      unit = notification.unit

      title = "#{notification.type_text}: #{unit.name} on #{notification.hostname}: #{unit.state_change.status_text}"
      message = "Systemd unit #{unit.name} on #{notification.hostname} #{unit.state_change.status_text}: #{unit.state.active} (#{unit.state.sub})"

      if unit.state_change.length > 1
        message << SystemdMon::Formatters::StateTableFormatter.new(unit).as_text
      end

      thread_id = "#{unit.name}-#{notification.hostname}"

      chat title, message, thread_id, color(notification.type), unit.state.active

      log "sent flowdock notification"
    end

  protected
    attr_accessor :client, :options

    def chat(title, message, thread_id, shade, status)
      client.post_to_thread(
         event: "activity",
         title: title,
	 external_thread_id: thread_id,
	 thread: {
	    title: title,
	    body: message,
	    status: {
	       color: shade,
 	       value: status
	    }
         }
      )
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
