class AddVersionToStoryFormats < ActiveRecord::Migration[6.0]
  def change
    add_column :story_formats, :version, :string
  end
end
