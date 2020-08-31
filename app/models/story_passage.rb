class StoryPassage < ApplicationRecord
  belongs_to :passage
  belongs_to :story, touch: true, counter_cache: true
end
