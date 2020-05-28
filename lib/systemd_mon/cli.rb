require 'yaml'
require 'systemd_mon'
require 'systemd_mon/monitor'
require 'systemd_mon/error'
require 'systemd_mon/dbus_manager'

module SystemdMon
  class CLI
    def initialize
      self.me      = "systemd_mon"
      self.verbose = true
    end

    def start
      yaml_config_file = ARGV.first
      self.options = load_and_validate_options(yaml_config_file)
      self.verbose = options['verbose'] || false
      Logger.verbose = verbose

      start_monitor

    rescue SystemdMon::Error => e
      err_string = e.message
      if verbose
        if e.original
          err_string << " - #{e.original.message} (#{e.original.class})"
          err_string << "\n\t#{e.original.backtrace.join("\n\t")}"
        else
          err_string << " (#{e.class})"
          err_string << "\n\t#{e.backtrace.join("\n\t")}"
        end
      end
      fatal_error(err_string)
    rescue => e
      err_string = e.message
      if verbose
        err_string << " (#{e.class})"
        err_string << "\n\t#{e.backtrace.join("\n\t")}"
      end
      fatal_error(err_string)
    end

  protected
    def start_monitor
      monitor = Monitor.new(options['hostname'] || `hostname`.strip, DBusManager.new)

      # Load units to monitor
      monitor.register_units options['units']

      options['notifiers'].each do |name, notifier_options|
        klass = NotifierLoader.new.get_class(name)
        monitor.add_notifier klass.new(notifier_options)
      end

      monitor.start
    end

    def load_and_validate_options(yaml_config_file)
      options = load_options(yaml_config_file)

      unless options.has_key?('notifiers') && options['notifiers'].any?
        fatal_error("no notifiers have been defined, there is no reason to continue")
      end
      unless options.has_key?('units') && options['units'].any?
        fatal_error("no units have been added for watching, there is no reason to continue")
      end
      options
    end

    def load_options(yaml_config_file)
      unless yaml_config_file && File.exists?(yaml_config_file)
        fatal_error "First argument must be a path to a YAML configuration file"
      end

      YAML.load_file(yaml_config_file)
    end

    def fatal_error(message, code = 255)
      $stderr.puts " #{me} error: #{message}"
      exit code
    end

  protected
    attr_accessor :verbose, :options, :me
  end
end
