class AddBodyToPassages < ActiveRecord::Migration[6.0]
  def change
    add_column :passages, :body_id, :integer
    add_column :passages, :body_type, :string, limit: 32
  end
end
