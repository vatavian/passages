require 'securerandom'
class Story < ApplicationRecord
  belongs_to :start_passage, class_name: 'Passage', optional: true
  belongs_to :style_p, class_name: 'Passage', optional: true
  belongs_to :user
  belongs_to :story_format
  has_many :story_passages, dependent: :destroy
  has_many :passages, through: :story_passages
  after_initialize :generate_ifid

  def generate_ifid
    self.ifid = SecureRandom.uuid.upcase if self.ifid.blank?
  end

  def copy
    new_story = Story.new
    new_story.user_id = user_id
    new_story.name = name
    new_story.start_passage_id = start_passage_id
    new_story.story_format_id = story_format_id
    new_story.zoom = zoom
    new_story.style_p_id = style_p_id
    new_story.script = script
    new_story
  end

  def style_s
    style_p&.content || ''
  end

  def style_s=(content)
    if !self.style_p && content&.strip.present?
      self.style_p = Passage.new
      self.style_p.user_id = user_id
      self.style_p.name = "Style for " + name
    end
    if self.style_p
      self.style_p.content = content
    end
  end

end
