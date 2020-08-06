class AddStylesheetScriptToStories < ActiveRecord::Migration[6.0]
  def change
    add_column :stories, :stylesheet, :text, null: true
    add_column :stories, :script, :text, null: true
  end
end
