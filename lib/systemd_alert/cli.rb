require 'yaml'

module SystemdAlert
  class CLI
    def initialize
      @me = "systemd_alert"
    end

    def start
      yaml_config_file = ARGV.first
      @options = load_and_validate_options(yaml_config_file)
    rescue => e
      fatal_error("#{e.message} (#{e.class})")
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
  end
end
