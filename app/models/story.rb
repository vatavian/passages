class Story < ApplicationRecord
  belongs_to :passage
  belongs_to :user
  belongs_to :story_format
end
