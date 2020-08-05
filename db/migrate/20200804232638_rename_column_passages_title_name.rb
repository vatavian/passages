class RenameColumnPassagesTitleName < ActiveRecord::Migration[6.0]
  def change
    rename_column :passages, :title, :name
  end
end
