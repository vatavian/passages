class FlowController < ApplicationController
  before_action :authenticate_user!
  before_action :set_story

  def edit
  end

  private
    def set_story
      @story = Story.find(params[:id])
    end
end