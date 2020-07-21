class CreatePassages < ActiveRecord::Migration[6.0]
  def change
    create_table :passages do |t|
      t.string :title

      t.timestamps
    end
  end
end
