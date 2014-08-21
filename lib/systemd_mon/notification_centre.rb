require 'systemd_mon/error'

module SystemdMon
  class NotificationCentre
    def initialize(notification_options)
      if notification_options.empty?
        raise NotificationError, "No notification services have been configured"
      end


    end
  end
end
