class FormattedStoryController < ApplicationController
  layout false
  before_action :set_story

  def show
    @header = @story.story_format.header.sub("~~story~~title~~", @story.name)
    @footer = @story.story_format.footer.sub("~~story~~title~~", @story.name)
    if @story.start_passage
      @startpid = @story.start_passage.story_passages.find_by(story_id: @story.id)&.sequence
    else
      @startpid = @story.story_passages[0].sequence
    end
  end

  private

    def set_story
      @story = Story.find(params[:id])
    end

end
