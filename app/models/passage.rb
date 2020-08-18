require 'securerandom'
class Passage < ApplicationRecord
  belongs_to :user, optional:true
  has_rich_text :body
  has_many :story_passages, dependent: :destroy
  has_many :stories, through: :story_passages
  after_initialize :generate_uuid

  def generate_uuid
    self.uuid = SecureRandom.uuid if self.uuid.blank?
  end

  def copy
    new_passage = Passage.new
    new_passage.user = user
    new_passage.body = body.to_s
    new_passage.name = name
    new_passage.uuid = SecureRandom.uuid
    new_passage
  end
end
