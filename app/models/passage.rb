class Passage < ApplicationRecord
  belongs_to :user, optional:true
  has_rich_text :body
end
