module SystemdMon
  class NotifierLoader
    def get_class(name)
      class_name = camel_case(name)
      get_class_const(class_name)
    rescue NameError
      require "systemd_mon/notifiers/#{name}"
      get_class_const(class_name)
    end

  protected
    def camel_case(name)
      return name if name !~ /_/ && name =~ /[A-Z]+.*/
      name.split('_').map { |e| e.capitalize }.join
    end

    def get_class_const(name)
      Notifiers.const_get(name)
    end
  end
end
