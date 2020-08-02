class AddFieldsToStory < ActiveRecord::Migration[6.0]
  def change
    add_column :stories, :name, :string
    add_column :stories, :ifid, :string
    add_column :stories, :zoom, :string
    rename_column :stories, :passage_id, :start_passage_id
  end
end
