module ApplicationHelper
  class Colm
    attr_reader   :sort_char, :field, :label, :row_blk
    def initialize(sort_char,  field,  label,  row_blk)
      @sort_char = sort_char
      @field = field
      @label = label
      @row_blk = row_blk
    end
  end

  def show_timestamp(utc_date)
    dt = utc_date.getlocal
    now = Time.now.getlocal
    if dt.year == now.year
      if dt.month == now.month && dt.day == now.day
        dt_format = current_user&.date_format_today || "Today %-k:%M"
      elsif dt > now.yesterday.midnight
        dt_format = current_user&.date_format_yesterday || "Yesterday %-k:%M"
      else
        dt_format = current_user&.date_format_this_year || "%b %-d %-k:%M"
      end
    else
      dt_format = current_user&.date_format_other_year || "%Y %b %-d %-k:%M"
    end
    zone = current_user&.time_zone || "UTC"
    time_tag(dt, dt.in_time_zone(zone).strftime(dt_format))
  end
end
