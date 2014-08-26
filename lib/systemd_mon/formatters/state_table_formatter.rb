require 'systemd_mon/formatters/base'
module SystemdMon::Formatters
  class StateTableFormatter < Base
    def as_text
      table = render_table
      lengths = table.transpose.map { |v| v.map(&:length).max }

      full_width = lengths.inject(&:+) + (lengths.length * 3) + 1
      div = " " + ("-" * full_width) + "\n"
      s = div.dup
      table.each do |row|
        s << " | "
        row.each_with_index { |col, i|
          s << col.ljust(lengths[i]) + " | "
        }
        s << "\n" + div.dup
      end
      s
    end

  protected
    def render_table
      changed = unit.state_change.diff
      table = []
      table << ["Time"].concat(changed.map{|v| v.first.display_name})
      changed.transpose.each do |vals|
        table << [vals.first.timestamp.strftime("%H:%M:%S.%3N %z")].concat(vals.map{|v| v.value})
      end
      table
    end
  end
end
