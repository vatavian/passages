class AddUuidToPassages < ActiveRecord::Migration[6.0]
  def change
    add_column :passages, :uuid, :string, limit: 36
  end
end
