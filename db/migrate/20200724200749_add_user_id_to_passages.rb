class AddUserIdToPassages < ActiveRecord::Migration[6.0]
  def change
    add_column :passages, :user_id, :integer
    add_index :passages, :user_id
  end
end
