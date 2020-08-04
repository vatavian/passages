class Story < ApplicationRecord
  belongs_to :start_passage, class_name: 'Passage', optional: true
  belongs_to :user
  belongs_to :story_format
  has_many :story_passages, dependent: :destroy
  has_many :passages, through: :story_passages
end
