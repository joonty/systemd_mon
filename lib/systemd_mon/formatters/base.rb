module SystemdMon::Formatters
  class Base
    def initialize(unit)
      self.unit = unit
    end

    def as_html
      raise "The formatter #{self.class} does not provide an html formatted string"
    end

    def as_text
      raise "The formatter #{self.class} does not provide a plain text string"
    end

  protected
    attr_accessor :unit
  end
end
