class CreateStoryFormats < ActiveRecord::Migration[6.0]
  def change
    create_table :story_formats do |t|
      t.string :name
      t.string :author
      t.text :header
      t.text :footer

      t.timestamps
    end
  end
end
