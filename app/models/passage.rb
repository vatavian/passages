class Passage < ApplicationRecord
  belongs_to :user, optional:true
  has_rich_text :body
  has_many :story_passages, dependent: :destroy
  has_many :stories, through: :story_passages
end
