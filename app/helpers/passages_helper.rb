module PassagesHelper

  def show_date(dt)
    if dt.year == Time.now.year
      dt.strftime(session[:date_format_this_year] || "%b %-d %-k:%M")
    else
      dt.strftime(session[:date_format_other_year] || "%Y %b %-d %-k:%M")
    end
  end
end
