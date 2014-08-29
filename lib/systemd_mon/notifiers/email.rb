require 'mail'
require 'systemd_mon/notifiers/base'
require 'systemd_mon/logger'
require 'systemd_mon/formatters/state_table_formatter'

module SystemdMon::Notifiers
  class Email < Base
    def initialize(*)
      super
      if options['smtp']
        opts = options
        Mail.defaults do
          delivery_method :smtp, Hash[opts['smtp'].map { |h, k| [h.to_sym, k] }]
        end
      end

      validate_options!
    end

    def notify!(notification)
      unit = notification.unit
      subject = "#{notification.type_text}: #{unit.name} on #{notification.hostname}: #{unit.state_change.status_text}"
      message = "Systemd unit #{unit.name} on #{notification.hostname} #{unit.state_change.status_text}: #{unit.state.active} (#{unit.state.sub})\n\n"
      if unit.state_change.length > 1
        message << SystemdMon::Formatters::StateTableFormatter.new(unit).as_text
      end
      message << "\nRegards, SystemdMon"

      send_mail subject, message

      log "sent email notification"
    end

  protected
    attr_accessor :options

    def validate_options!
      unless options.has_key?("to")
        raise NotifierError, "The 'to' address must be set to use the email notifier"
      end
      true
    end

    def send_mail(subject, message)
      debug("Sending email to #{options['to']}:")
      debug(%Q{ -> Subject: "#{subject}"})
      debug(%Q{ -> Message: "#{message}"})

      mail = Mail.new do
        subject subject
        body message
      end
      mail.to = options['to']
      if options['from']
        mail.from options['from']
      end
      mail.deliver!
    end
  end
end
