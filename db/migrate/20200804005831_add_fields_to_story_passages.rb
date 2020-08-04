class AddFieldsToStoryPassages < ActiveRecord::Migration[6.0]
  def change
    change_column :story_passages, :sequence, :integer, null: true
    add_column :story_passages, :tags, :string, null: true
    add_column :story_passages, :position, :string, null: true
    add_column :story_passages, :size, :string, null: true
  end
end
