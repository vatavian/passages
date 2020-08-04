class MakeStartPassageIdOptional < ActiveRecord::Migration[6.0]
  def change
    change_column :stories, :start_passage_id, :integer, null: true
  end
end
