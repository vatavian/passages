class FormattedStoryController < ApplicationController
  layout false
  before_action :set_story

  def show
    @header = @story.story_format.header.sub("~~story~~title~~", @story.name)
    @footer = @story.story_format.footer.sub("~~story~~title~~", @story.name)
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
