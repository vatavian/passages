class Passage < ApplicationRecord
  belongs_to :user, optional:true
  has_rich_text :body
  has_many :story_passages, dependent: :destroy
  has_many :stories, through: :story_passages

  def copy
    new_passage = Passage.new
    new_passage.user = user
    new_passage.body = body.to_s
    new_passage.title = title

    new_passage
  end
end
