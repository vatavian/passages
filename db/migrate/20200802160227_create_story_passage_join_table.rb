class CreateStoryPassageJoinTable < ActiveRecord::Migration[6.0]
  def change
    create_table :story_passages do |t|
      t.references :story, null: false
      t.references :passage, null: false
      t.integer :sequence
      t.timestamps
    end
  end
end
