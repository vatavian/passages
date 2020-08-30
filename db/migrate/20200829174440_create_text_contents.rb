class CreateTextContents < ActiveRecord::Migration[6.0]
  def change
    create_table :text_contents do |t|
      t.text :content
      t.timestamps
    end
  end
end
