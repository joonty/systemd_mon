require 'mail'
require 'systemd_mon/logger'

module SystemdMon::Notifiers
  class Email
    def initialize(options)
      self.options = options
      if options['smtp']
        Mail.defaults do
          delivery_method :smtp, Hash[options['smtp'].map { |h, k| [h.to_sym, k] }]
        end
      end

      validate_options!
    end

    def notify!(notification)
      unit = notification.unit
      subject = "#{unit.name} on #{notification.hostname}: #{unit.state_change.status_text}"
      message = "Systemd unit #{unit.name} on #{notification.hostname} status: #{unit.state_change.status_text}\n"
      message << "#{unit.state_change.last.active} (#{unit.state_change.last.sub})"
      message << "\nRegards, SystemdMon"

      send_mail subject, message
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
      SystemdMon::Logger.debug("Sending email to #{options['to']}:")
      SystemdMon::Logger.debug(%Q{ -> Subject: "#{subject}"})
      SystemdMon::Logger.debug(%Q{ -> Message: "#{message}"})

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
