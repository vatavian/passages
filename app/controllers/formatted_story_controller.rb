class FormattedStoryController < ApplicationController
  layout false
  before_action :set_story

  def show
    if !params[:format] || !(format = StoryFormat.find_by(id: params[:format]))
      format = @story.story_format
    end
    @header = format.header.gsub("{{STORY_NAME}}", @story.name)
    @footer = format.footer.gsub("{{STORY_NAME}}", @story.name)
    if @story.start_passage
      @startpid = @story.start_passage.uuid
    elsif @story.story_passages.length > 0
      @startpid = @story.story_passages[0].passage.uuid
    else
      @startpid = nil
    end
    # TODO: embed images: require 'base64' Base64.encode64(data) or strict_encode64
  end

  private

    def set_story
      @story = Story.find(params[:id])
    end

end
