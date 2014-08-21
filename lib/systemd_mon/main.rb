require 'dbus'
require 'mail'
require 'yaml'

MAIL_OPTS = { :address              => "smtp.gmail.com",
            :port                 => 587,
            :domain               => 'ggapps.co.uk',
            :user_name            => 'notifications@ggapps.co.uk',
            :password             => 'p34nh4m!',
            :authentication       => 'plain',
            :enable_starttls_auto => true  }

Mail.defaults do
  delivery_method :smtp, MAIL_OPTS
end

options = YAML.load_file($ARGV[0])
raise options.inspect


MONITOR = %w(unicorn.service)

bus = DBus::SystemBus.instance
systemd_service = bus.service('org.freedesktop.systemd1')
systemd = systemd_service.object('/org/freedesktop/systemd1')
systemd.introspect
systemd.Subscribe
u = systemd.GetUnit('unicorn.service')
unicorn = systemd_service.object(u.first)
unicorn.introspect
unicorn.default_iface = "org.freedesktop.DBus.Properties"
unicorn.on_signal("PropertiesChanged") { |u, v| puts "Changed"; p u; p v}

main = DBus::Main.new
main << bus
main.run
loop do
  units = systemd.ListUnits().first
  MONITOR.each do |unit_name|
    unit = units.find { |unit| unit.first == unit_name }
    if unit
      if unit[3] != "active"
        puts "Alert: #{unit[0]} not active"
      end
    else
      puts "Unknown service: #{unit_name}"
    end
  end
  sleep 10
end
