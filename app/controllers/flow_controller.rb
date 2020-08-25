class FlowController < ApplicationController
  before_action :authenticate_user!
  before_action :set_story

  def edit
    if @story&.name
      @section_title = 'Flow of ' + @story.name
    else
      @section_title = 'Flow'
    end
  end

  private

  def set_story
    @story = Story.find(params[:id])
  end
end