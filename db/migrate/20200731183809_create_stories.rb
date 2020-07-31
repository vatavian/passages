class CreateStories < ActiveRecord::Migration[6.0]
  def change
    create_table :stories do |t|
      t.references :passage, null: false, foreign_key: true
      t.references :user, null: false, foreign_key: true
      t.references :story_format, null: false, foreign_key: true

      t.timestamps
    end
  end
end
