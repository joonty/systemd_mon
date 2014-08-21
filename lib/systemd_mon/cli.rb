require 'yaml'
require 'systemd_mon/monitor'
require 'systemd_mon/error'
require 'systemd_mon/dbus_manager'

module SystemdMon
  class CLI
    def initialize
      @me = "systemd_mon"
      @verbose = true
    end

    def start
      yaml_config_file = ARGV.first
      @options = load_and_validate_options(yaml_config_file)

      monitor = Monitor.new(DBusManager.new)
      monitor.register_units @options['units']
      monitor.start
    rescue SystemdMon::Error => e
      err_string = e.message
      if verbose
        err_string << " - #{e.original.message} (#{e.original.class})"
        err_string << "\n\t#{e.original.backtrace.join("\n\t")}"
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
      $stderr.puts " #{@me} error: #{message}"
      exit code
    end

  protected
    attr_reader :verbose
  end
end
