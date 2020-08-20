class AddDateFormatToUsers < ActiveRecord::Migration[6.0]
  def change
    add_column :users, :time_zone, :string, limit: 32, default: "UTC"
    add_column :users, :date_format_yesterday, :string, limit: 32, default: "Yesterday %-k:%M"
    add_column :users, :date_format_today, :string, limit: 32, default: "Today %-k:%M"
    add_column :users, :date_format_this_year, :string, limit: 32, default: "%b %-d %-k:%M"
    add_column :users, :date_format_other_year, :string, limit: 32, default: "%Y %b %-d %-k:%M"
  end
end
