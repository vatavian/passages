class FormattedStoryController < ApplicationController
  layout false
  before_action :set_story

  def show
    @body = @story.passage.body.to_s
    # Skip ActionText's leading and trailing div tags
    @body = @body[34..-15]
    Rails.logger.debug "@story.story_format.name = " + @story.story_format.name
    @format_name, @format_version = @story.story_format.name.split(' ')
    Rails.logger.debug "@format_name = " + @format_name
    Rails.logger.debug "@format_version = " + @format_version
  end

  private

    def set_story
      @story = Story.find(params[:id])
    end

end
