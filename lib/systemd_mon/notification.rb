module SystemdMon
  class Notification
    def initialize(message, type = :alert)
      self.message = message
      self.type    = type
    end

    def self.types
      [:alert, :warning, :ok]
    end
  end
end
